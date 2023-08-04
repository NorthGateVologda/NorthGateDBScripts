update northgate.facility f set geometry = ST_Point(f.y, f.x, 4326);
commit;
