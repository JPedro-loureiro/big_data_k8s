CREATE TABLE delta_lake.bronze.order_products(
	id integer,
	order_id integer,
    product_id integer,
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
  location = 's3a://datalake/bronze/order_products/'
)