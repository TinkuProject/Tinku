-- Keep the recorded route segment calculation and widen its default radius.
CREATE OR REPLACE FUNCTION refresh_entity_transport_relations(
  p_entity_type visit_entity,
  p_entity_id bigint,
  p_lat double precision,
  p_lng double precision,
  p_radius_m integer DEFAULT 1000
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  affected integer := 0;
BEGIN
  DELETE FROM entity_transport_relations
  WHERE entity_type = p_entity_type
    AND entity_id = p_entity_id
    AND source = 'auto';

  WITH entity_point AS (
    SELECT ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography AS point
  ),
  route_shapes AS (
    SELECT
      tr.transport_line_id,
      tr.direction,
      ST_MakeLine(tr.location::geometry ORDER BY tr.stop_order)::geography AS path
    FROM transport_routes tr
    JOIN transport_lines tl ON tl.id = tr.transport_line_id
    WHERE tl.status = 'active'
    GROUP BY tr.transport_line_id, tr.direction
    HAVING COUNT(*) >= 2
  ),
  nearby_candidates AS (
    SELECT rs.transport_line_id, ST_Distance(rs.path, ep.point) AS distance_m
    FROM route_shapes rs
    CROSS JOIN entity_point ep
    WHERE ST_DWithin(rs.path, ep.point, p_radius_m)
    UNION ALL
    SELECT tr.transport_line_id, ST_Distance(tr.location, ep.point) AS distance_m
    FROM transport_routes tr
    JOIN transport_lines tl ON tl.id = tr.transport_line_id
    CROSS JOIN entity_point ep
    WHERE tl.status = 'active'
      AND ST_DWithin(tr.location, ep.point, p_radius_m)
  ),
  nearby_lines AS (
    SELECT transport_line_id, MIN(distance_m)::integer AS distance_m
    FROM nearby_candidates
    GROUP BY transport_line_id
  )
  INSERT INTO entity_transport_relations (
    entity_type,
    entity_id,
    transport_line_id,
    distance_m,
    radius_m,
    source,
    computed_at
  )
  SELECT
    p_entity_type,
    p_entity_id,
    transport_line_id,
    distance_m,
    p_radius_m,
    'auto',
    CURRENT_TIMESTAMP
  FROM nearby_lines
  ON CONFLICT (entity_type, entity_id, transport_line_id)
  DO UPDATE SET
    distance_m = EXCLUDED.distance_m,
    radius_m = EXCLUDED.radius_m,
    source = EXCLUDED.source,
    computed_at = EXCLUDED.computed_at;

  GET DIAGNOSTICS affected = ROW_COUNT;
  RETURN affected;
END;
$$;

CREATE OR REPLACE FUNCTION refresh_all_entity_transport_relations(
  p_radius_m integer DEFAULT 1000
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  item record;
  affected integer := 0;
BEGIN
  FOR item IN
    SELECT
      'business'::visit_entity AS entity_type,
      id AS entity_id,
      ST_Y(location::geometry) AS lat,
      ST_X(location::geometry) AS lng
    FROM businesses
    WHERE location IS NOT NULL
      AND status IN ('active', 'pending')

    UNION ALL

    SELECT
      'event'::visit_entity AS entity_type,
      id AS entity_id,
      ST_Y(location::geometry) AS lat,
      ST_X(location::geometry) AS lng
    FROM events
    WHERE location IS NOT NULL
      AND status IN ('active', 'pending')

    UNION ALL

    SELECT
      'tourist_place'::visit_entity AS entity_type,
      id AS entity_id,
      ST_Y(location::geometry) AS lat,
      ST_X(location::geometry) AS lng
    FROM tourist_places
    WHERE location IS NOT NULL
      AND status IN ('active', 'inactive')
  LOOP
    affected := affected + refresh_entity_transport_relations(
      item.entity_type,
      item.entity_id,
      item.lat,
      item.lng,
      p_radius_m
    );
  END LOOP;

  RETURN affected;
END;
$$;

SELECT refresh_all_entity_transport_relations(1000);
