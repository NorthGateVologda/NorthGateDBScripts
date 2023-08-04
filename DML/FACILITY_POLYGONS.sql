with a as (
	select
		f.facility_id f_id,
		p.id p_id
	from facility f
	inner join polygons_lens p
	on ST_contains(p.geometry, f.geometry)
)
insert into northgate.facility_polygons (
	facility_id,
	polygon_id
)
select f_id, p_id from a;

commit;
