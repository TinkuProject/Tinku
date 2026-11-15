-- Parche para arreglar el bug de stock ilimitado (NULL) en las publicaciones.
-- Ejecuta este script directamente en tu base de datos de producción (PostgreSQL).

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

  -- BUGS FIXED HERE: Only check limit if stock is NOT NULL
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
    'active'
  )
  RETURNING * INTO v_publication;

  RETURN v_publication;
END;
$$;

-- -----------------------------------------------------------------------------
-- ACTUALIZAR PUBLICACIÓN EXISTENTE
-- -----------------------------------------------------------------------------
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
  v_unit_price numeric;
  v_unit_tinku_price int;
  v_payment_mode text;
  v_stock_diff int;
  v_cost int;
BEGIN
  SELECT *
  INTO v_publication
  FROM product_publications
  WHERE id = p_publication_id
    AND status = 'active'
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

  -- BUGS FIXED HERE: Only check limit if stock is NOT NULL
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

  v_unit_price := COALESCE(p_unit_price, v_publication.unit_price, v_product.price);
  v_unit_tinku_price := COALESCE(p_unit_tinku_price, v_publication.unit_tinku_price, v_product.tinku_price::int);
  v_payment_mode := COALESCE(
    NULLIF(TRIM(p_payment_mode), ''),
    v_publication.payment_mode,
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

  v_stock_diff := p_published_stock - v_publication.published_stock;

  IF v_stock_diff > 0 THEN
    v_cost := calculate_product_publication_cost(
      v_stock_diff,
      CASE WHEN v_payment_mode IN ('money', 'both') THEN v_unit_price ELSE 0 END,
      CASE WHEN v_payment_mode IN ('tinkus', 'both') THEN v_unit_tinku_price ELSE 0 END
    );
  ELSE
    v_cost := 0;
  END IF;

  IF v_cost > 0 THEN
    PERFORM perform_tinku_spend(
      p_user_id,
      v_cost,
      'product_publication_update',
      v_publication.id,
      'Product marketplace publication update'
    );
  END IF;

  UPDATE product_publications
  SET
    published_stock = p_published_stock,
    unit_price = CASE WHEN v_payment_mode IN ('money', 'both') THEN v_unit_price ELSE NULL END,
    unit_tinku_price = CASE WHEN v_payment_mode IN ('tinkus', 'both') THEN v_unit_tinku_price ELSE NULL END,
    payment_mode = v_payment_mode,
    calculated_cost_tinkus = calculated_cost_tinkus + v_cost,
    charged_tinkus = charged_tinkus + v_cost,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = v_publication.id
  RETURNING * INTO v_publication;

  RETURN v_publication;
END;
$$;
