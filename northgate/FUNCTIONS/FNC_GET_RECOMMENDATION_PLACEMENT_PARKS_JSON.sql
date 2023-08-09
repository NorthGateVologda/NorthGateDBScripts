CREATE OR REPLACE FUNCTION northgate.fnc_get_recommendation_placement_parks_json() RETURNS JSON 
AS 
$$
SELECT json_agg(row_to_json(v.*)) AS JSON
FROM
  (SELECT v.id AS polygon_id,
          v.rating,
          v.population,
          v.nmb_of_residential_bld,
          v.nmb_of_soc_infr_bld,
          v.nmb_of_tourism_bld,
          v.nmb_of_bsns_bld AS nmb_of_business_bld,
          v.nmb_of_trnsp_inf_bld,
          v.nmb_of_parks,
          v.recommendation,
          v.nmb_of_all,
          10700 AS max_population,
          4 AS max_rating
   FROM northgate.recommendation_placement_parks v
   WHERE v.nmb_of_all > 0) v;
$$
LANGUAGE SQL;