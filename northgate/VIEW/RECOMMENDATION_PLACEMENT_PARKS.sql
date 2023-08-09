WITH polygons AS
  (SELECT p.id,
          p.geometry,
          p.population,
          p.nmb_of_residential_bld,
          p.nmb_of_soc_infr_bld,
          p.nmb_of_tourism_bld,
          p.nmb_of_bsns_bld,
          p.nmb_of_trnsp_inf_bld,
          p.nmb_of_parks,
          p.nmb_of_residential_bld + p.nmb_of_soc_infr_bld + p.nmb_of_tourism_bld + p.nmb_of_bsns_bld + p.nmb_of_trnsp_inf_bld + p.nmb_of_parks AS nmb_of_all
   FROM
     (SELECT p_1.id,
             p_1.geometry,
             floor(p_1.population) AS population,
             floor(p_1.nmb_of_residential_bld::double precision) AS nmb_of_residential_bld,
             floor(p_1.nmb_of_soc_infr_bld::double precision) AS nmb_of_soc_infr_bld,
             floor(p_1.nmb_of_tourism_bld::double precision) AS nmb_of_tourism_bld,
             floor(p_1.nmb_of_bsns_bld::double precision) AS nmb_of_bsns_bld,
             floor(p_1.nmb_of_trnsp_inf_bld::double precision) AS nmb_of_trnsp_inf_bld,
             floor(p_1.nmb_of_parks::double precision) AS nmb_of_parks
      FROM
        (SELECT pl.id,
                pl.geometry,
                sum(COALESCE(round(f.number_of_inhabitants::numeric, 2), 0.00)) AS population,
                sum(CASE
                        WHEN f.type2::text = 'Дом'::text THEN 1
                        ELSE 0
                    END) AS nmb_of_residential_bld,
                sum(CASE
                        WHEN f.type2::text = 'Объекты социальной инфраструктуры'::text THEN 1
                        ELSE 0
                    END) AS nmb_of_soc_infr_bld,
                sum(CASE
                        WHEN f.type2::text = 'Объекты туризма'::text THEN 1
                        ELSE 0
                    END) AS nmb_of_tourism_bld,
                sum(CASE
                        WHEN f.type2::text = 'Объекты бизнеса'::text THEN 1
                        ELSE 0
                    END) AS nmb_of_bsns_bld,
                sum(CASE
                        WHEN f.type2::text = 'Объект транспортной инфраструктуры'::text THEN 1
                        ELSE 0
                    END) AS nmb_of_trnsp_inf_bld,
                sum(CASE
                        WHEN f.type2::text = 'Парк'::text THEN 1
                        ELSE 0
                    END) AS nmb_of_parks
         FROM polygons_lens pl
         LEFT JOIN facility f ON st_contains(pl.geometry, f.geometry)
         GROUP BY pl.id,
                  pl.geometry) p_1) p),
     polygons_with_parks AS
  (SELECT pl.id,
          pl.geometry,
          pl.population,
          pl.nmb_of_residential_bld,
          pl.nmb_of_soc_infr_bld,
          pl.nmb_of_tourism_bld,
          pl.nmb_of_bsns_bld,
          pl.nmb_of_trnsp_inf_bld,
          pl.nmb_of_parks,
          pl.nmb_of_all
   FROM polygons pl
   WHERE (EXISTS
            (SELECT NULL::text AS text
             FROM parks_lens prks
             WHERE st_intersects(prks.geometry, pl.geometry))) ),
     mdn_buildings AS
  (SELECT
     (SELECT percentile_cont(0.5::double precision) WITHIN GROUP (
                                                                  ORDER BY v_1.nmb_of_bsns_bld) AS percentile_cont
      FROM
        (SELECT pwp.nmb_of_bsns_bld
         FROM polygons_with_parks pwp
         WHERE pwp.nmb_of_bsns_bld > 0::double precision) v_1) AS median_bsns_bld,

     (SELECT percentile_cont(0.5::double precision) WITHIN GROUP (
                                                                  ORDER BY v_1.nmb_of_soc_infr_bld) AS percentile_cont
      FROM
        (SELECT pwp.nmb_of_soc_infr_bld
         FROM polygons_with_parks pwp
         WHERE pwp.nmb_of_soc_infr_bld > 0::double precision) v_1) AS median_soc_infr_bld,

     (SELECT percentile_cont(0.5::double precision) WITHIN GROUP (
                                                                  ORDER BY v_1.nmb_of_trnsp_inf_bld) AS percentile_cont
      FROM
        (SELECT pwp.nmb_of_trnsp_inf_bld
         FROM polygons_with_parks pwp
         WHERE pwp.nmb_of_trnsp_inf_bld > 0::double precision) v_1) AS median_trnsp_inf_bld,

     (SELECT percentile_cont(0.5::double precision) WITHIN GROUP (
                                                                  ORDER BY v_1.nmb_of_tourism_bld) AS percentile_cont
      FROM
        (SELECT pwp.nmb_of_tourism_bld
         FROM polygons_with_parks pwp
         WHERE pwp.nmb_of_tourism_bld > 0::double precision) v_1) AS median_tourism_bld,

     (SELECT percentile_cont(0.5::double precision) WITHIN GROUP (
                                                                  ORDER BY v_1.nmb_of_parks) AS percentile_cont
      FROM
        (SELECT pwp.nmb_of_parks
         FROM polygons_with_parks pwp
         WHERE pwp.nmb_of_parks > 0::double precision) v_1) AS median_parks),
     polygons_parks_rating AS
  (SELECT v_1.id,
          v_1.geometry,
          v_1.bsns_effect + v_1.soc_infr_effect + v_1.trnsp_inf_effect + v_1.tourism_effect + v_1.park_effect AS rating
   FROM
     (SELECT v_2.id,
             v_2.geometry,
             CASE
                 WHEN v_2.bsns_effect > 1::numeric THEN 1::numeric
                 ELSE v_2.bsns_effect
             END AS bsns_effect,
             CASE
                 WHEN v_2.soc_infr_effect > 1::numeric THEN 1::numeric
                 ELSE v_2.soc_infr_effect
             END AS soc_infr_effect,
             CASE
                 WHEN v_2.trnsp_inf_effect > 1::numeric THEN 1::numeric
                 ELSE v_2.trnsp_inf_effect
             END AS trnsp_inf_effect,
             CASE
                 WHEN v_2.tourism_effect > 1::numeric THEN 1::numeric
                 ELSE v_2.tourism_effect
             END AS tourism_effect,
             v_2.park_effect
      FROM
        (SELECT v_3.id,
                v_3.geometry,
                round((v_3.nmb_of_bsns_bld / COALESCE(NULLIF(mb.median_bsns_bld, 0::double precision), 1::double precision) * 0.15::double precision)::numeric, 2) AS bsns_effect,
                round((v_3.nmb_of_soc_infr_bld / COALESCE(NULLIF(mb.median_soc_infr_bld, 0::double precision), 1::double precision) * 0.1::double precision)::numeric, 2) AS soc_infr_effect,
                round((v_3.nmb_of_trnsp_inf_bld / COALESCE(NULLIF(mb.median_trnsp_inf_bld, 0::double precision), 1::double precision) * 0.1::double precision)::numeric, 2) AS trnsp_inf_effect,
                round((v_3.nmb_of_tourism_bld / COALESCE(NULLIF(mb.median_tourism_bld, 0::double precision), 1::double precision) * 0.3::double precision)::numeric, 2) AS tourism_effect,
                round((v_3.nmb_of_parks / COALESCE(NULLIF(mb.median_parks, 0::double precision), 1::double precision))::numeric, 2) AS park_effect
         FROM
           (SELECT pwp.id,
                   pwp.geometry,
                   pwp.population,
                   pwp.nmb_of_residential_bld,
                   pwp.nmb_of_soc_infr_bld,
                   pwp.nmb_of_tourism_bld,
                   pwp.nmb_of_bsns_bld,
                   pwp.nmb_of_trnsp_inf_bld,
                   pwp.nmb_of_parks
            FROM polygons_with_parks pwp
            WHERE pwp.population > 0::numeric
              OR pwp.nmb_of_all > 0::double precision) v_3
         CROSS JOIN mdn_buildings mb) v_2) v_1),
     adjacent_polygons AS
  (SELECT pl.id,
          round(max(pr.rating) / 2::numeric, 2) AS rating
   FROM
     (SELECT pl_1.id,
             pl_1.geometry
      FROM polygons pl_1
      WHERE NOT (EXISTS
                   (SELECT NULL::text AS text
                    FROM polygons_parks_rating pr_1
                    WHERE pl_1.id = pr_1.id))
        AND (pl_1.population > 0::numeric
             OR pl_1.nmb_of_all > 0::double precision)) pl
   JOIN polygons_parks_rating pr ON st_touches(pl.geometry, pr.geometry)
   GROUP BY pl.id),
     polygons_rating AS
  (SELECT polygons_parks_rating.id,
          polygons_parks_rating.rating
   FROM polygons_parks_rating
   UNION ALL SELECT adjacent_polygons.id,
                    adjacent_polygons.rating
   FROM adjacent_polygons),
     PARAMETERS AS
  (SELECT
     (SELECT avg(p.population) AS AVG
      FROM polygons p
      WHERE p.population > 0::numeric) AS avg_population,

     (SELECT avg(v_1.rating_peopl) AS AVG
      FROM
        (SELECT pr.rating / p.population AS rating_peopl
         FROM polygons_rating pr
         JOIN polygons p ON pr.id = p.id
         WHERE p.population > 0::numeric) v_1) AS avg_rating_peopl)
SELECT v.id,
       v.geometry,
       v.rating,
       v.population,
       v.nmb_of_residential_bld,
       v.nmb_of_soc_infr_bld,
       v.nmb_of_tourism_bld,
       v.nmb_of_bsns_bld,
       v.nmb_of_trnsp_inf_bld,
       v.nmb_of_parks,
       v.nmb_of_all,
       CASE
           WHEN v.population > par.avg_population
                AND v.nmb_of_parks = 0::double precision THEN 1
           WHEN v.population > par.avg_population
                AND (v.rating / v.population) > par.avg_rating_peopl THEN 1
           ELSE 0
       END AS recommendation
FROM
  (SELECT v_1.id,
          v_1.geometry,
          v_1.rating,
          v_1.population,
          v_1.nmb_of_residential_bld,
          v_1.nmb_of_soc_infr_bld,
          v_1.nmb_of_tourism_bld,
          v_1.nmb_of_bsns_bld,
          v_1.nmb_of_trnsp_inf_bld,
          v_1.nmb_of_parks,
          v_1.nmb_of_all
   FROM
     (SELECT pl.id,
             pl.geometry,
             pl.population,
             pl.nmb_of_residential_bld,
             pl.nmb_of_soc_infr_bld,
             pl.nmb_of_tourism_bld,
             pl.nmb_of_bsns_bld,
             pl.nmb_of_trnsp_inf_bld,
             pl.nmb_of_parks,
             pl.nmb_of_all,
             COALESCE(pr.rating, 0.00) AS rating
      FROM polygons pl
      LEFT JOIN polygons_rating pr ON pl.id = pr.id) v_1
   GROUP BY v_1.id,
            v_1.geometry,
            v_1.rating,
            v_1.population,
            v_1.nmb_of_residential_bld,
            v_1.nmb_of_soc_infr_bld,
            v_1.nmb_of_tourism_bld,
            v_1.nmb_of_bsns_bld,
            v_1.nmb_of_trnsp_inf_bld,
            v_1.nmb_of_parks,
            v_1.nmb_of_all) v
CROSS JOIN PARAMETERS par
ORDER BY v.rating,
         v.population DESC;