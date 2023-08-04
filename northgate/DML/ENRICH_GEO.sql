with linestring as (
	select
		id as record_id,
		(format('LINESTRING(%s %s, %s %s, %s %s, %s %s, %s %s)',
			miny, minx,
			miny, maxx,
			maxy, maxx,
	    	maxy, minx,
	    	miny, minx)
		 	::text) as geostr,
		(format('[[[%s, %s], [%s, %s], [%s, %s], [%s, %s], [%s, %s]]]',
			miny, minx,
			miny, maxx,
			maxy, maxx,
	    	maxy, minx,
	    	miny, minx)
		 	::text) as jsonstr
	from northgate.parks_lens
), geom as (
	select record_id, ST_GeomFromText(geostr) geo, jsonstr
	from linestring
)
update northgate.parks_lens set
geometry = geo,
geo_lens = jsonstr
from geom
where id = record_id;

commit;
