# import libraries
import os
from delta.tables import *
from pyspark.sql import SparkSession
from pyspark import SparkConf

# main spark program
# init application
if __name__ == '__main__':

    # get environment variables
    app_table_name = os.getenv('APP_TABLE_NAME')
    table_name = os.getenv('TABLE_NAME')
    full_table_name = os.getenv('FULL_TABLE_NAME')

    # funcs
    def 

    # init session
    # set configs
    spark = (
        SparkSession
        .builder
        .appName(f"{app_table_name}-landing-to-bronze")
        .config("spark.hadoop.fs.s3a.endpoint", "http://minio.datalake.svc.cluster.local:9000/")
        .config("spark.hadoop.fs.s3a.access.key", "T11ZDXNGN4MCJF2PZ393")
        .config("spark.hadoop.fs.s3a.secret.key", "gvrgSv49v4ZPgBqnOPQFh3iR7rxti+iEC8WOWM10")
        .config("spark.hadoop.fs.s3a.path.style.access", True)
        .config("spark.hadoop.fs.s3a.fast.upload", True)
        .config("spark.hadoop.fs.s3a.multipart.size", 104857600)
        .config("fs.s3a.connection.maximum", 100)
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
        .config("spark.delta.logStore.class", "org.apache.spark.sql.delta.storage.S3SingleDriverLogStore")
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
        # .config("hive.metastore.uris", "thrift://hive-metastore.data-exploration.svc.cluster.local:9083")
        # .config("spark.sql.warehouse.dir", "s3a://hive-metastore/warehouse/")
        # .enableHiveSupport()
        .getOrCreate()
    )

    # show configured parameters
    print(SparkConf().getAll())

    # set log level
    spark.sparkContext.setLogLevel("ERROR")

    # get table schema
    table_schema = (
        spark
        .sql(f"select * from bronze.{table_name} limit 0")
        .schema
    )

    print(f"Table schema: {table_schema}")

    # [landing zone area]
    print(f"Reading {table_name} form landing-zone.")
    files_path = f"s3a://datalake/landing-zone/{full_table_name}/*/*/*/*/"

    df = (
        spark.read.format("parquet")
        # .schema(table_schema)
        .load(files_path)
    )

    # get DataFrame schema
    df_schema = df.schema

    # [bronze zone area]
    print(f"Writing {table_name} to bronze layer.")
    write_delta_mode = "overwrite"
    delta_bronze_zone = "s3a://datalake/bronze"
    df.write.mode(write_delta_mode).format("delta").save(f"{delta_bronze_zone}/{table_name}/")

    # stop session
    spark.stop()
