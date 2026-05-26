from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, IntegerType
from pyspark.sql.functions import from_json, col

# 1. Khởi tạo "Bộ não" Spark (Chế độ Test)
spark = SparkSession.builder \
    .appName("Test_Kafka_Connection") \
    .getOrCreate()

# Tắt bớt log rác của Spark để dễ nhìn kết quả
spark.sparkContext.setLogLevel("WARN")

# 2. Tạo một cái khuôn (Schema) mini - Chỉ lấy 3 cột để test nhanh
test_schema = StructType([
    StructField("artist", StringType(), True),
    StructField("song", StringType(), True),
    StructField("userId", IntegerType(), True)
])

print(">>> [TEST] Đang mở đường ống cắm vào Kafka...")

# 3. Đọc dữ liệu từ trạm Kafka (Đọc lại từ đầu năm 2026)
kafka_df = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "broker:29092") \
    .option("subscribe", "listen_events") \
    .option("startingOffsets", "earliest") \
    .load()

# 4. Ép kiểu Binary thành Text và nhét vào cái khuôn Schema mini
parsed_df = kafka_df.selectExpr("CAST(value AS STRING) as json_str") \
    .withColumn("data", from_json(col("json_str"), test_schema)) \
    .select("data.*")

print(">>> [TEST] Đã kết nối! Đang in dữ liệu trực tiếp ra màn hình...")

# 5. Xả thẳng dữ liệu ra Console (màn hình Terminal) để xem bằng mắt thật
query = parsed_df.writeStream \
    .format("console") \
    .outputMode("append") \
    .start()

query.awaitTermination()