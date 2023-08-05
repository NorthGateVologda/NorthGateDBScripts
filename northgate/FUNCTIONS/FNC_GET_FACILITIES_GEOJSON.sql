CREATE OR REPLACE FUNCTION fnc_get_facilities_geoJson() RETURNS JSON
	AS
	$$
	SELECT   json_build_object(
                'type', 
                'FeatureCollection',
                'features', 
                json_agg(ST_AsGeoJSON(v.*)::json)
             ) AS geoJson
    FROM     (SELECT   f.geometry AS point,
                       f.name,
                       f.type2 AS type,
                       number_of_inhabitants AS population
              FROM     facility f) v;
	$$
	LANGUAGE SQL;