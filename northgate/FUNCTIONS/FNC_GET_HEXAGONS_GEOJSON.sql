CREATE OR REPLACE FUNCTION fnc_get_hexagons_geoJson() RETURNS JSON
AS
$$
SELECT json_build_object('type', 'FeatureCollection', 'features', json_agg(ST_AsGeoJSON(v.*)::JSON)) AS geoJson
FROM
  (SELECT v.id,
          v.hexagon,
          v.population
   FROM
     (SELECT pl.id,
             pl.geometry AS hexagon,
             FLOOR(SUM(COALESCE(CAST(f.number_of_inhabitants AS DECIMAL), 0))) AS population,
             COUNT(f.facility_id) AS number_of_buildings
      FROM polygons_lens pl
      LEFT JOIN facility_polygons fp ON pl.id = fp.polygon_id
      LEFT JOIN facility f ON fp.facility_id = f.facility_id
      GROUP BY pl.id,
               pl.geometry) v
   WHERE v.number_of_buildings > 0) v;
$$
LANGUAGE SQL;