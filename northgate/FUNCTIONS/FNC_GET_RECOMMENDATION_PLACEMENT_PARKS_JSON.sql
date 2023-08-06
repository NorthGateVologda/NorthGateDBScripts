CREATE OR REPLACE FUNCTION fnc_get_recommendation_placement_parks_json() RETURNS JSON
AS
$$
WITH params AS
  (SELECT 0.0045045045 AS distance),
     avg_blds AS
  (SELECT
     (SELECT AVG(nmb_all) AS nmb_all
      FROM
        (SELECT COUNT(f.facility_id) AS nmb_all
         FROM polygons_lens pl
         INNER JOIN facility_polygons fp ON pl.id = fp.polygon_id
         INNER JOIN facility f ON fp.facility_id = f.facility_id
         GROUP BY pl.id) v) AS avg_all_blds,

     (SELECT AVG(avg_soc_infr_blds) AS avg_soc_infr_blds
      FROM
        (SELECT COUNT(f.facility_id) AS avg_soc_infr_blds
         FROM polygons_lens pl
         INNER JOIN facility_polygons fp ON pl.id = fp.polygon_id
         INNER JOIN facility f ON f.type2 = 'Объекты социальной инфраструктуры'
         AND fp.facility_id = f.facility_id
         GROUP BY pl.id) v) AS avg_soc_infr_blds,

     (SELECT AVG(avg_trnsp_inf_blds) AS avg_trnsp_inf_blds
      FROM
        (SELECT COUNT(f.facility_id) AS avg_trnsp_inf_blds
         FROM polygons_lens pl
         INNER JOIN facility_polygons fp ON pl.id = fp.polygon_id
         INNER JOIN facility f ON f.type2 = 'Объект транспортной инфраструктуры'
         AND fp.facility_id = f.facility_id
         GROUP BY pl.id) v) AS avg_trnsp_inf_blds,

     (SELECT AVG(avg_tourism_blds) AS avg_tourism_blds
      FROM
        (SELECT COUNT(f.facility_id) AS avg_tourism_blds
         FROM polygons_lens pl
         INNER JOIN facility_polygons fp ON pl.id = fp.polygon_id
         INNER JOIN facility f ON f.type2 = 'Объекты туризма'
         AND fp.facility_id = f.facility_id
         GROUP BY pl.id) v) AS avg_tourism_blds),
     parks AS
  (SELECT id,
          geometry,
          park_rating
   FROM
     (SELECT id,
             geometry,
             (coverage + bsns_effect + soc_infr_effect + trnsp_inf_effect + tourism_effect) AS park_rating
      FROM
        (SELECT id,
                geometry,
                coverage * 0.35 AS coverage,
                (nmb_all_of_blds / COALESCE(NULLIF(ab.avg_all_blds, 0), 1)) * 0.15 AS bsns_effect,
                (nmb_of_soc_infr_bld / COALESCE(NULLIF(ab.avg_soc_infr_blds, 0), 1)) * 0.1 AS soc_infr_effect,
                (nmb_of_trnsp_inf_bld / COALESCE(NULLIF(ab.avg_trnsp_inf_blds, 0), 1)) * 0.1 AS trnsp_inf_effect,
                (nmb_of_tourism_bld / COALESCE(NULLIF(ab.avg_tourism_blds, 0), 1)) * 0.3 AS tourism_effect
         FROM
           (SELECT v.id,
                   v.geometry,
                   v.avg_park_population / v.avg_population AS coverage,
                   COUNT(f.facility_id) AS nmb_all_of_blds,
                   SUM(CASE
                           WHEN f.type2 = 'Объекты социальной инфраструктуры' THEN 1
                           ELSE 0
                       END) AS nmb_of_soc_infr_bld,
                   SUM(CASE
                           WHEN f.type2 = 'Объект транспортной инфраструктуры' THEN 1
                           ELSE 0
                       END) AS nmb_of_trnsp_inf_bld,
                   SUM(CASE
                           WHEN f.type2 = 'Объекты туризма' THEN 1
                           ELSE 0
                       END) AS nmb_of_tourism_bld
            FROM
              (SELECT pl.id,
                      pl.geometry,
                      AVG(COALESCE(CAST(f.number_of_inhabitants AS DECIMAL), 0)) AS avg_park_population,

                 (SELECT AVG(t.sum_population)
                  FROM
                    (SELECT SUM(COALESCE(CAST(f.number_of_inhabitants AS DECIMAL), 0)) AS sum_population
                     FROM polygons_lens AS pl
                     LEFT JOIN facility_polygons fp ON pl.id = fp.polygon_id
                     LEFT JOIN facility f ON fp.facility_id = f.facility_id
                     GROUP BY pl.id) t) AS avg_population
               FROM parks_lens pl
               CROSS JOIN params
               LEFT JOIN facility f ON ST_DWithin(f.geometry, pl.geometry, params.distance)
               GROUP BY pl.id,
                        pl.geometry) v
            CROSS JOIN params
            LEFT JOIN facility f ON ST_DWithin(f.geometry, v.geometry, params.distance)
            GROUP BY v.id,
                     v.geometry,
                     v.avg_park_population / v.avg_population) v
         CROSS JOIN avg_blds ab) v) v),
     polygons AS
  (SELECT pl.id AS polygon_id,
          pl.geometry,
          SUM(CASE
                  WHEN f.type2 = 'Дом' THEN 1
                  ELSE 0
              END) AS nmb_of_residential_bld,
          SUM(COALESCE(CAST(f.number_of_inhabitants AS DECIMAL), 0)) AS population,
          SUM(CASE
                  WHEN f.type2 = 'Объекты социальной инфраструктуры' THEN 1
                  ELSE 0
              END) AS nmb_of_soc_infr_bld,
          SUM(CASE
                  WHEN f.type2 = 'Объекты туризма' THEN 1
                  ELSE 0
              END) AS nmb_of_tourism_bld,
          SUM(CASE
                  WHEN f.type2 = 'Объекты бизнеса' THEN 1
                  ELSE 0
              END) AS nmb_of_business_bld,
          SUM(CASE
                  WHEN f.type2 = 'Объект транспортной инфраструктуры' THEN 1
                  ELSE 0
              END) AS nmb_of_trnsp_inf_bld,
          SUM(CASE
                  WHEN f.type2 = 'Парк' THEN 1
                  ELSE 0
              END) AS nmb_of_parks
   FROM polygons_lens AS pl
   LEFT JOIN facility_polygons fp ON pl.id = fp.polygon_id
   LEFT JOIN facility f ON fp.facility_id = f.facility_id
   GROUP BY pl.id,
            pl.geometry),
     polygons_avg AS
  (SELECT AVG(v.nmb_of_residential_bld) AS avg_res_bsn,
          AVG(v.nmb_of_soc_infr_bld) AS avg_nfr,
          AVG(v.nmb_of_tourism_bld) AS avg_tourism,
          AVG(v.nmb_of_business_bld) AS avg_business,
          AVG(v.nmb_of_trnsp_inf_bld) AS avg_trnsp,
          AVG(v.nmb_of_parks) AS avg_parks
   FROM polygons v),
     RESULT AS
  (SELECT p.*
   FROM
     (SELECT p.polygon_id,
             FLOOR(p.population) AS population,
             FLOOR(p.nmb_of_residential_bld) AS nmb_of_residential_bld,
             FLOOR(p.nmb_of_soc_infr_bld) AS nmb_of_soc_infr_bld,
             FLOOR(p.nmb_of_tourism_bld) AS nmb_of_tourism_bld,
             FLOOR(p.nmb_of_business_bld) AS nmb_of_business_bld,
             FLOOR(p.nmb_of_trnsp_inf_bld) AS nmb_of_trnsp_inf_bld,
             FLOOR(p.nmb_of_parks) AS nmb_of_parks,
             FLOOR(p.polygon_comfort_rating) AS polygon_comfort_rating,
             p.recommendation,
             CASE
                 WHEN distantion <= params.distance THEN ROUND(CAST(((1 - (distantion / params.distance)) * 100) AS DECIMAL), 2)
                 ELSE 0
             END AS availability_of_parks
      FROM
        (SELECT p.polygon_id,
                p.population,
                p.nmb_of_residential_bld,
                p.nmb_of_soc_infr_bld,
                p.nmb_of_tourism_bld,
                p.nmb_of_business_bld,
                p.nmb_of_trnsp_inf_bld,
                p.nmb_of_parks,
                p.recommendation,
                p.park_rating,
                MAX(p.distantion) AS distantion,
                p.polygon_comfort_rating
         FROM
           (SELECT p.polygon_id,
                   p.population,
                   p.nmb_of_residential_bld,
                   p.nmb_of_soc_infr_bld,
                   p.nmb_of_tourism_bld,
                   p.nmb_of_business_bld,
                   p.nmb_of_trnsp_inf_bld,
                   p.nmb_of_parks,
                   p.recommendation,
                   p.polygon_comfort_rating,
                   pr.park_rating AS park_rating,
                   ST_Distance(p.geometry, pr.geometry) AS distantion
            FROM
              (SELECT p.polygon_id,
                      p.geometry,
                      p.population,
                      p.nmb_of_residential_bld,
                      p.nmb_of_soc_infr_bld,
                      p.nmb_of_tourism_bld,
                      p.nmb_of_business_bld,
                      p.nmb_of_trnsp_inf_bld,
                      p.nmb_of_parks,
                      CASE
                          WHEN (p.population > 1632
                                AND p.nmb_of_parks < 1
                                AND p.polygon_comfort_rating > 100) THEN 'Да'
                          ELSE 'Нет'
                      END AS recommendation,
                      p.polygon_comfort_rating
               FROM
                 (SELECT p.polygon_id,
                         p.geometry,
                         p.population,
                         p.nmb_of_residential_bld,
                         p.nmb_of_soc_infr_bld,
                         p.nmb_of_tourism_bld,
                         p.nmb_of_business_bld,
                         p.nmb_of_trnsp_inf_bld,
                         p.nmb_of_parks,
                         (ratio_res_bsn + ration_nfr + ratio_tourism + ratio_business + ratio_trnsp + ratio_parks) AS polygon_comfort_rating
                  FROM
                    (SELECT p.polygon_id,
                            p.geometry,
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
                     FROM polygons p
                     CROSS JOIN polygons_avg pa) p) p) p
            CROSS JOIN params
            LEFT JOIN parks pr ON ST_DWithin(p.geometry, pr.geometry, params.distance)
            AND pr.park_rating =
              (SELECT MAX(park_rating)
               FROM parks pr
               CROSS JOIN params
               WHERE ST_DWithin(p.geometry, geometry, params.distance))) p
         GROUP BY p.polygon_id,
                  p.population,
                  p.nmb_of_residential_bld,
                  p.nmb_of_soc_infr_bld,
                  p.nmb_of_tourism_bld,
                  p.nmb_of_business_bld,
                  p.nmb_of_trnsp_inf_bld,
                  p.nmb_of_parks,
                  p.recommendation,
                  p.park_rating,
                  p.polygon_comfort_rating) p
      CROSS JOIN params) p)
SELECT json_agg(row_to_json(v.*)) AS JSON
FROM
  (SELECT r.*,
     (SELECT MAX(population)
      FROM result) AS max_population,
     (SELECT MAX(polygon_comfort_rating)
      FROM result) AS max_polygon_comfort_rating
   FROM result r) v;
$$
LANGUAGE SQL;