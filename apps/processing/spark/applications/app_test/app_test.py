# import libraries
from delta.tables import *
from pyspark.sql import SparkSession
from pyspark import SparkConf

# main spark program
# init application
if __name__ == '__main__':

    # init session
    # set configs
    spark = SparkSession \
        .builder \
        .appName("app_test") \
        .config("spark.hadoop.fs.s3a.endpoint", "http://minio.datalake.svc.cluster.local:9000/") \
        .config("spark.hadoop.fs.s3a.access.key", "T11ZDXNGN4MCJF2PZ393") \
        .config("spark.hadoop.fs.s3a.secret.key", "gvrgSv49v4ZPgBqnOPQFh3iR7rxti+iEC8WOWM10") \
        .config("spark.hadoop.fs.s3a.path.style.access", True) \
        .config("spark.hadoop.fs.s3a.fast.upload", True) \
        .config("spark.hadoop.fs.s3a.multipart.size", 104857600) \
        .config("fs.s3a.connection.maximum", 100) \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.delta.logStore.class", "org.apache.spark.sql.delta.storage.S3SingleDriverLogStore") \
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
        .getOrCreate()

    # show configured parameters
    print(SparkConf().getAll())

    # set log level
    spark.sparkContext.setLogLevel("INFO")

    # set location of files
    # minio data lake engine

    # [landing zone area]
    # device and subscription
    order_products_files = "s3a://datalake/landing-zone/src_data_generator_postgres.public.order_products"

    # read order products data
    # json file from landing zone
    df_order_products = spark.read \
        .parquet(order_products_files) \
        .option("inferSchema", "true") \
        .option("header", "true")

    # get number of partitions
    print(df_order_products.rdd.getNumPartitions())

    # count amount of rows ingested from lake
    print(df_order_products.count())

    # [bronze zone area]
    # data lakehouse paradigm
    # need to read the entire landing zone
    write_delta_mode = "overwrite"
    delta_bronze_zone = "s3a://datalake/bronze"
    df_order_products.write.mode(write_delta_mode).format("delta").save(delta_bronze_zone + "/order_products/")

    # stop session
    spark.stop()
