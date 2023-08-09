CREATE OR REPLACE FUNCTION fnc_get_facilities_geoJson() RETURNS JSON
AS
$$
SELECT json_build_object('type', 'FeatureCollection', 'features', json_agg(ST_AsGeoJSON(v.*)::JSON)) AS geoJson
FROM
  (SELECT ST_Buffer(f.geometry::geography, 22) AS POINT,
          f.name,
          f.type2 AS TYPE,
          number_of_inhabitants AS population
   FROM facility f
   WHERE f.type2 != 'Дом') v;
$$
LANGUAGE SQL;