CREATE TABLE delta_lake.bronze.users(
	id integer,
	name varchar,
    birth_date date,
	tel_number varchar,
    email varchar,
    password varchar,
	created_at bigint,
	updated_at bigint,
	__op varchar,
	__db varchar,
	__table varchar,
	__schema varchar,
	__source_ts_ms bigint,
	__deleted varchar,
	test_col varchar
)
WITH (
  location = 's3a://datalake/bronze/users/'
)