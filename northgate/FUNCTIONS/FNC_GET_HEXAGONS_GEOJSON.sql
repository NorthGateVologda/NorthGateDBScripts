CREATE OR REPLACE FUNCTION fnc_get_hexagons_geoJson() RETURNS JSON
	AS
	$$
	SELECT   json_build_object(
                'type', 
                'FeatureCollection',
                'features', 
                json_agg(ST_AsGeoJSON(v.*)::json)
             ) AS geoJson
    FROM     (SELECT   pl.geometry AS hexagon,
                       FLOOR(SUM(COALESCE(CAST(f.number_of_inhabitants AS DECIMAL), 0))) AS population
              FROM     polygons_lens pl
                       LEFT JOIN facility_polygons fp
                          ON pl.id = fp.polygon_id
                       LEFT JOIN facility f
                          ON fp.facility_id = f.facility_id
              GROUP BY pl.geometry) v;
	$$
	LANGUAGE SQL;