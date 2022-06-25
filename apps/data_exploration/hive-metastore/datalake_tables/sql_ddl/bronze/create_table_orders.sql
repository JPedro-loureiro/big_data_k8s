CREATE TABLE delta_lake.bronze.orders(
	id integer,
	user_id integer,
    order_date TIMESTAMP(3) WITH TIME ZONE,
	order_price real,
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
  location = 's3a://datalake/bronze/orders/'
)