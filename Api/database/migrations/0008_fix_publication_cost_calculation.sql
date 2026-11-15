-- Fix calculation of additional cost when updating stock

CREATE OR REPLACE FUNCTION create_product_publication_with_charge(
  p_user_id uuid,
  p_product_id bigint,
  p_published_stock int,
  p_unit_price numeric DEFAULT NULL,
  p_unit_tinku_price int DEFAULT NULL,
  p_payment_mode text DEFAULT NULL
)
RETURNS product_publications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product products%ROWTYPE;
  v_business businesses%ROWTYPE;
  v_unit_price numeric;
  v_unit_tinku_price int;
  v_payment_mode text;
  v_cost int;
  v_publication product_publications;
BEGIN
  SELECT *
  INTO v_product
  FROM products
  WHERE id = p_product_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  IF v_product.stock IS NOT NULL AND v_product.stock < p_published_stock THEN
    RAISE EXCEPTION 'Published stock exceeds available stock';
  END IF;

  SELECT *
  INTO v_business
  FROM businesses
  WHERE id = v_product.business_id;

  IF NOT FOUND OR v_business.owner_id <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF NOT v_business.validated OR v_business.status <> 'active' THEN
    RAISE EXCEPTION 'Business must be approved to publish products';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM product_publications
    WHERE product_id = p_product_id
      AND status <> 'archived'
  ) THEN
    RAISE EXCEPTION 'Product already has an open publication';
  END IF;

  v_unit_price := COALESCE(p_unit_price, v_product.price);
  v_unit_tinku_price := COALESCE(p_unit_tinku_price, v_product.tinku_price::int);
  v_payment_mode := COALESCE(
    NULLIF(TRIM(p_payment_mode), ''),
    CASE
      WHEN v_unit_price IS NOT NULL AND v_unit_tinku_price IS NOT NULL THEN 'both'
      WHEN v_unit_price IS NOT NULL THEN 'money'
      ELSE 'tinkus'
    END
  );

  IF v_payment_mode NOT IN ('money', 'tinkus', 'both') THEN
    RAISE EXCEPTION 'Invalid payment mode';
  END IF;

  IF (v_payment_mode = 'money' AND v_unit_price IS NULL)
    OR (v_payment_mode = 'tinkus' AND v_unit_tinku_price IS NULL)
    OR (v_payment_mode = 'both' AND (v_unit_price IS NULL OR v_unit_tinku_price IS NULL)) THEN
    RAISE EXCEPTION 'Publication price is required for selected payment mode';
  END IF;

  UPDATE products
  SET
    price = CASE WHEN v_payment_mode IN ('money', 'both') THEN v_unit_price ELSE price END,
    tinku_price = CASE WHEN v_payment_mode IN ('tinkus', 'both') THEN v_unit_tinku_price ELSE tinku_price END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = v_product.id;

  v_cost := calculate_product_publication_cost(
    p_published_stock,
    CASE WHEN v_payment_mode IN ('money', 'both') THEN v_unit_price ELSE 0 END,
    CASE WHEN v_payment_mode IN ('tinkus', 'both') THEN v_unit_tinku_price ELSE 0 END
  );

  IF v_cost > 0 THEN
    PERFORM perform_tinku_spend(
      p_user_id,
      v_cost,
      'product_publication',
      p_product_id,
      'Product marketplace publication'
    );
  END IF;

  INSERT INTO product_publications (
    product_id,
    business_id,
    created_by,
    published_stock,
    unit_price,
    unit_tinku_price,
    payment_mode,
    calculated_cost_tinkus,
    charged_tinkus,
    status
  )
  VALUES (
    v_product.id,
    v_product.business_id,
    p_user_id,
    p_published_stock,
    CASE WHEN v_payment_mode IN ('money', 'both') THEN v_unit_price ELSE NULL END,
    CASE WHEN v_payment_mode IN ('tinkus', 'both') THEN v_unit_tinku_price ELSE NULL END,
    v_payment_mode,
    v_cost,
    v_cost,
    CASE WHEN p_published_stock = 0 THEN 'draft'::marketplace_publication_status ELSE 'active'::marketplace_publication_status END
  )
  RETURNING * INTO v_publication;

  INSERT INTO product_publication_history (
    publication_id,
    changed_by,
    previous_stock,
    new_stock,
    previous_cost_tinkus,
    new_cost_tinkus,
    additional_charged_tinkus,
    reason
  )
  VALUES (
    v_publication.id,
    p_user_id,
    NULL,
    p_published_stock,
    NULL,
    v_cost,
    v_cost,
    'initial_publication'
  );

  RETURN v_publication;
END;
$$;

CREATE OR REPLACE FUNCTION update_product_publication_with_charge(
  p_user_id uuid,
  p_publication_id bigint,
  p_published_stock int,
  p_unit_price numeric DEFAULT NULL,
  p_unit_tinku_price int DEFAULT NULL,
  p_payment_mode text DEFAULT NULL
)
RETURNS product_publications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_publication product_publications%ROWTYPE;
  v_product products%ROWTYPE;
  v_business businesses%ROWTYPE;
  v_payment_mode text;
  v_unit_price numeric;
  v_unit_tinku_price int;
  v_new_cost int;
  v_additional int;
BEGIN
  SELECT *
  INTO v_publication
  FROM product_publications
  WHERE id = p_publication_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product publication not found';
  END IF;

  SELECT *
  INTO v_product
  FROM products
  WHERE id = v_publication.product_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  IF v_product.stock IS NOT NULL AND v_product.stock < p_published_stock THEN
    RAISE EXCEPTION 'Published stock exceeds available stock';
  END IF;

  SELECT *
  INTO v_business
  FROM businesses
  WHERE id = v_publication.business_id;

  IF NOT FOUND OR v_business.owner_id <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF NOT v_business.validated OR v_business.status <> 'active' THEN
    RAISE EXCEPTION 'Business must be approved to publish products';
  END IF;

  v_payment_mode := COALESCE(NULLIF(TRIM(p_payment_mode), ''), v_publication.payment_mode, 'both');
  v_unit_price := COALESCE(p_unit_price, v_publication.unit_price, v_product.price);
  v_unit_tinku_price := COALESCE(p_unit_tinku_price, v_publication.unit_tinku_price, v_product.tinku_price::int);

  IF v_payment_mode NOT IN ('money', 'tinkus', 'both') THEN
    RAISE EXCEPTION 'Invalid payment mode';
  END IF;

  IF (v_payment_mode = 'money' AND v_unit_price IS NULL)
    OR (v_payment_mode = 'tinkus' AND v_unit_tinku_price IS NULL)
    OR (v_payment_mode = 'both' AND (v_unit_price IS NULL OR v_unit_tinku_price IS NULL)) THEN
    RAISE EXCEPTION 'Publication price is required for selected payment mode';
  END IF;

  UPDATE products
  SET
    price = CASE WHEN v_payment_mode IN ('money', 'both') THEN v_unit_price ELSE price END,
    tinku_price = CASE WHEN v_payment_mode IN ('tinkus', 'both') THEN v_unit_tinku_price ELSE tinku_price END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = v_product.id;

  v_new_cost := calculate_product_publication_cost(
    p_published_stock,
    CASE WHEN v_payment_mode IN ('money', 'both') THEN v_unit_price ELSE 0 END,
    CASE WHEN v_payment_mode IN ('tinkus', 'both') THEN v_unit_tinku_price ELSE 0 END
  );

  v_additional := GREATEST(v_new_cost - v_publication.charged_tinkus, 0);

  IF v_additional > 0 THEN
    PERFORM perform_tinku_spend(
      p_user_id,
      v_additional,
      'product_publication_update',
      p_publication_id,
      'Product marketplace publication update'
    );
  END IF;

  INSERT INTO product_publication_history (
    publication_id,
    changed_by,
    previous_stock,
    new_stock,
    previous_cost_tinkus,
    new_cost_tinkus,
    additional_charged_tinkus,
    reason
  )
  VALUES (
    v_publication.id,
    p_user_id,
    v_publication.published_stock,
    p_published_stock,
    v_publication.calculated_cost_tinkus,
    v_new_cost,
    v_additional,
    'publication_update'
  );

  UPDATE product_publications
  SET
    published_stock = p_published_stock,
    unit_price = CASE WHEN v_payment_mode IN ('money', 'both') THEN v_unit_price ELSE NULL END,
    unit_tinku_price = CASE WHEN v_payment_mode IN ('tinkus', 'both') THEN v_unit_tinku_price ELSE NULL END,
    payment_mode = v_payment_mode,
    calculated_cost_tinkus = v_new_cost,
    charged_tinkus = charged_tinkus + v_additional,
    status = CASE
      WHEN p_published_stock = 0 THEN 'sold_out'::marketplace_publication_status
      WHEN status = 'sold_out' THEN 'active'::marketplace_publication_status
      ELSE status
    END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = v_publication.id
  RETURNING * INTO v_publication;

  RETURN v_publication;
END;
$$;
