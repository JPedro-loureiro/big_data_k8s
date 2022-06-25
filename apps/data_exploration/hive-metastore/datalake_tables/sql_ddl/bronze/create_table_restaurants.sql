CREATE TABLE delta_lake.bronze.restaurants(
	id integer,
	name varchar,
	tel_number varchar,
	created_at bigint,
	updated_at bigint,
	__op varchar,
	__db varchar,
	__table varchar,
	__schema varchar,
	__source_ts_ms bigint,
	__deleted varchar
)
WITH (
  location = 's3a://datalake/bronze/restaurants/'
)