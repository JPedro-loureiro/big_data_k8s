CREATE TABLE minio.bronze.products(
	id integer,
	name varchar,
	restaurant_id integer,
	price real,
	created_at bigint,
	__op varchar,
	__db varchar,
	__table varchar,
	__schema varchar,
	__source_ts_ms bigint,
	__deleted varchar,
	test_col varchar
)
WITH (
  location = 's3a://datalake/bronze/products/'
)