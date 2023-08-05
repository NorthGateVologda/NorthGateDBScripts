CREATE OR REPLACE FUNCTION fnc_get_recommendation_placement_parks_json() RETURNS JSON
AS
	$$
	WITH     polygons AS (SELECT   pl.id AS polygon_id,
								   SUM(CASE WHEN f.type2 = 'Дом' THEN 1 ELSE 0 END) AS nmb_of_residential_bld,
								   SUM(COALESCE(CAST(f.number_of_inhabitants AS DECIMAL), 0)) AS population,
								   SUM(CASE WHEN f.type2 = 'Объекты социальной инфраструктуры' THEN 1 ELSE 0 END) AS nmb_of_soc_infr_bld,
								   SUM(CASE WHEN f.type2 = 'Объекты туризма' THEN 1 ELSE 0 END) AS nmb_of_tourism_bld,
								   SUM(CASE WHEN f.type2 = 'Объекты бизнеса' THEN 1 ELSE 0 END) AS nmb_of_business_bld,
								   SUM(CASE WHEN f.type2 = 'Объект транспортной инфраструктуры' THEN 1 ELSE 0 END) AS nmb_of_trnsp_inf_bld,
								   SUM(CASE WHEN f.type2 = 'Парк' THEN 1 ELSE 0 END) AS nmb_of_parks
						  FROM     polygons_lens AS pl
								   LEFT JOIN facility_polygons fp
									  ON pl.id = fp.polygon_id
								   LEFT JOIN facility f
									  ON fp.facility_id = f.facility_id
						  GROUP BY pl.id),
			 polygons_avg AS (SELECT   AVG(v.nmb_of_residential_bld) AS avg_res_bsn,
									   AVG(v.nmb_of_soc_infr_bld) AS avg_nfr,
									   AVG(v.nmb_of_tourism_bld) AS avg_tourism,
									   AVG(v.nmb_of_business_bld) AS avg_business,
									   AVG(v.nmb_of_trnsp_inf_bld) AS avg_trnsp,
									   AVG(v.nmb_of_parks) AS avg_parks
							  FROM     polygons v)
	SELECT   json_agg(row_to_json(p.*)) AS json
	FROM     (SELECT   p.polygon_id,
					   p.population,
					   p.nmb_of_residential_bld,
					   p.nmb_of_soc_infr_bld,
					   p.nmb_of_tourism_bld,
					   p.nmb_of_business_bld,
					   p.nmb_of_trnsp_inf_bld,
					   p.nmb_of_parks,
					   CASE
						  WHEN (p.population > 1632 AND p.nmb_of_parks < 1 AND p.polygon_comfort_rating > 100)
						  THEN 'Да'
						  ELSE 'Нет'
					   END AS recommendation
			FROM       (SELECT   p.polygon_id,
								 p.population,
								 p.nmb_of_residential_bld,
								 p.nmb_of_soc_infr_bld,
								 p.nmb_of_tourism_bld,
								 p.nmb_of_business_bld,
								 p.nmb_of_trnsp_inf_bld,
								 p.nmb_of_parks,
								 (ratio_res_bsn + ration_nfr + ratio_tourism + 
								  ratio_business + ratio_trnsp + ratio_parks) AS polygon_comfort_rating
						FROM     (SELECT   p.polygon_id,
										   p.population,
										   p.nmb_of_residential_bld,
										   p.nmb_of_soc_infr_bld,
										   p.nmb_of_tourism_bld,
										   p.nmb_of_business_bld,
										   p.nmb_of_trnsp_inf_bld,
										   p.nmb_of_parks,
										   (p.nmb_of_residential_bld / pa.avg_res_bsn) * 100 AS ratio_res_bsn,
										   (p.nmb_of_soc_infr_bld / pa.avg_nfr) * 30 AS ration_nfr,
										   (p.nmb_of_tourism_bld / pa.avg_tourism) * 50 AS ratio_tourism,
										   (p.nmb_of_business_bld / pa.avg_business) * 50 AS ratio_business,
										   (p.nmb_of_trnsp_inf_bld / pa.avg_trnsp) * 30 AS ratio_trnsp,
										   (p.nmb_of_parks / pa.avg_parks) * 100 AS ratio_parks
								  FROM     polygons p
										   CROSS JOIN polygons_avg pa) p) p) p;
	$$
	LANGUAGE SQL;