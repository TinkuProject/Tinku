-- Cobra la creación de almacenes de socios usando el mismo costo de negocios.
-- Admin/master siguen pudiendo crear almacenes desde API sin cargo operativo.

CREATE OR REPLACE FUNCTION create_warehouse_with_charge(
  p_user_id uuid,
  p_name text,
  p_description text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_email text DEFAULT NULL,
  p_address text DEFAULT NULL,
  p_lat double precision DEFAULT NULL,
  p_lng double precision DEFAULT NULL
)
RETURNS warehouses
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cost numeric;
  v_warehouse warehouses;
BEGIN
  IF current_app_user_id() IS NULL OR p_user_id <> current_app_user_id() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT value::numeric
  INTO v_cost
  FROM system_config
  WHERE key = 'business_create_cost';

  IF v_cost IS NULL THEN
    RAISE EXCEPTION 'Business cost not configured';
  END IF;

  INSERT INTO warehouses(
    owner_id,
    name,
    description,
    phone,
    email,
    address,
    location,
    validated,
    status
  )
  VALUES (
    p_user_id,
    p_name,
    p_description,
    p_phone,
    p_email,
    p_address,
    CASE
      WHEN p_lat IS NULL OR p_lng IS NULL THEN NULL
      ELSE ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    END,
    false,
    'pending'
  )
  RETURNING * INTO v_warehouse;

  PERFORM perform_tinku_spend(
    p_user_id,
    v_cost,
    'warehouse_creation',
    v_warehouse.id,
    'Creación de almacén'
  );

  PERFORM write_audit_log(
    p_user_id,
    'warehouse_created_with_charge',
    'warehouse',
    v_warehouse.id,
    jsonb_build_object(
      'cost', v_cost
    )
  );

  RETURN v_warehouse;
END;
$$;

ALTER FUNCTION create_warehouse_with_charge(uuid, text, text, text, text, text, double precision, double precision)
OWNER TO postgres;

GRANT EXECUTE ON FUNCTION create_warehouse_with_charge(
  uuid, text, text, text, text, text, double precision, double precision
) TO PUBLIC;
