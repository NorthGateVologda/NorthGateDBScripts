with a as (
	select
		id as p_id,
		jsonb_array_elements(geometry_lens::jsonb) as j
	from polygons_lens
), b as (
	select
		p_id
		,((j -> 0) -> 0)::real as y1
		,((j -> 0) -> 1)::real as x1
		,((j -> 1) -> 0)::real as y2
		,((j -> 1) -> 1)::real as x2
		,((j -> 2) -> 0)::real as y3
		,((j -> 2) -> 1)::real as x3
		,((j -> 3) -> 0)::real as y4
		,((j -> 3) -> 1)::real as x4
		,((j -> 4) -> 0)::real as y5
		,((j -> 4) -> 1)::real as x5
		,((j -> 5) -> 0)::real as y6
		,((j -> 5) -> 1)::real as x6
		,((j -> 6) -> 0)::real as y7
		,((j -> 6) -> 1)::real as x7
	from a
), c as (
	select
		p_id,
		(format('LINESTRING(%s %s, %s %s, %s %s, %s %s, %s %s, %s %s, %s %s)',
			x1, y1,
			x2, y2,
			x3, y3,
			x4, y4,
			x5, y5,
			x6, y6,
			x7, y7)
			::text) as geostr
	from b
), d as (
	select
		p_id,
		ST_MakePolygon(geostr) geo
	from c
)
update northgate.polygons_lens set
geometry = geo
from d
where id = p_id;

commit;
