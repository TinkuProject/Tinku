UPDATE product_publications
SET
  payment_mode = 'tinkus',
  unit_price = NULL,
  status = CASE
    WHEN unit_tinku_price IS NULL OR unit_tinku_price <= 0 THEN 'archived'::marketplace_publication_status
    ELSE status
  END,
  unit_tinku_price = CASE
    WHEN unit_tinku_price IS NULL OR unit_tinku_price <= 0 THEN 1
    ELSE unit_tinku_price
  END,
  updated_at = CURRENT_TIMESTAMP
WHERE payment_mode <> 'tinkus'
   OR unit_price IS NOT NULL
   OR unit_tinku_price IS NULL
   OR unit_tinku_price <= 0;

ALTER TABLE product_publications
  ALTER COLUMN payment_mode SET DEFAULT 'tinkus';

ALTER TABLE product_publications
  DROP CONSTRAINT IF EXISTS product_publications_payment_mode_check;

ALTER TABLE product_publications
  ADD CONSTRAINT product_publications_payment_mode_check
  CHECK (payment_mode = 'tinkus');

ALTER TABLE product_publications
  DROP CONSTRAINT IF EXISTS product_publications_payment_required_check;

ALTER TABLE product_publications
  ADD CONSTRAINT product_publications_payment_required_check
  CHECK (
    unit_price IS NULL
    AND unit_tinku_price IS NOT NULL
    AND unit_tinku_price > 0
  );

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
  v_unit_tinku_price int;
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

  IF p_unit_price IS NOT NULL
     OR COALESCE(NULLIF(TRIM(p_payment_mode), ''), 'tinkus') <> 'tinkus' THEN
    RAISE EXCEPTION 'Marketplace publications only support Tinkus';
  END IF;

  IF COALESCE(v_product.stock, 0) < p_published_stock THEN
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

  v_unit_tinku_price := COALESCE(p_unit_tinku_price, v_product.tinku_price::int);

  IF v_unit_tinku_price IS NULL OR v_unit_tinku_price <= 0 THEN
    RAISE EXCEPTION 'Tinku price is required';
  END IF;

  UPDATE products
  SET
    tinku_price = v_unit_tinku_price,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = v_product.id;

  v_cost := calculate_product_publication_cost(
    p_published_stock,
    0,
    v_unit_tinku_price
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
    NULL,
    v_unit_tinku_price,
    'tinkus',
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

  IF p_unit_price IS NOT NULL
     OR COALESCE(NULLIF(TRIM(p_payment_mode), ''), 'tinkus') <> 'tinkus' THEN
    RAISE EXCEPTION 'Marketplace publications only support Tinkus';
  END IF;

  IF COALESCE(v_product.stock, 0) < p_published_stock THEN
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

  v_unit_tinku_price := COALESCE(
    p_unit_tinku_price,
    v_publication.unit_tinku_price,
    v_product.tinku_price::int
  );

  IF v_unit_tinku_price IS NULL OR v_unit_tinku_price <= 0 THEN
    RAISE EXCEPTION 'Tinku price is required';
  END IF;

  UPDATE products
  SET
    tinku_price = v_unit_tinku_price,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = v_product.id;

  v_new_cost := calculate_product_publication_cost(
    p_published_stock,
    0,
    v_unit_tinku_price
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
    unit_price = NULL,
    unit_tinku_price = v_unit_tinku_price,
    payment_mode = 'tinkus',
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
