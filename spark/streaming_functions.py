from pyspark.sql.functions import from_json, col, month, hour, dayofmonth, year, udf
from pyspark.sql.types import StringType

# 1. Vũ khí sửa lỗi font chữ do Eventsim sinh ra
@udf(returnType=StringType())
def string_decode(s, encoding='utf-8'):
    if s:
        try:
            return (s.encode('latin1')      
                    .decode('unicode-escape')
                    .encode('latin1')   
                    .decode(encoding)    
                    .strip('\"'))
        except Exception:
            return s
    return s

# 2. Hàm cắm ống hút vào Kafka
def create_kafka_read_stream(spark, kafka_address, kafka_port, topic, starting_offset="earliest"):
    return (spark
            .readStream
            .format("kafka")
            .option("kafka.bootstrap.servers", f"{kafka_address}:{kafka_port}")
            .option("failOnDataLoss", False)
            .option("startingOffsets", starting_offset)
            .option("subscribe", topic)
            .load())

# 3. Hàm bóc tách, gọt giũa dữ liệu
def process_stream(stream, stream_schema, topic):
    # Ép chuỗi Binary thành JSON và gắn khuôn
    stream = (stream
              .selectExpr("CAST(value AS STRING)")
              .select(from_json(col("value"), stream_schema).alias("data"))
              .select("data.*"))

    # Đổi ts (mili-giây) sang Timestamp và chẻ ra năm/tháng/ngày/giờ
    stream = (stream
              .withColumn("ts", (col("ts")/1000).cast("timestamp"))
              .withColumn("year", year(col("ts")))
              .withColumn("month", month(col("ts")))
              .withColumn("day", dayofmonth(col("ts")))
              .withColumn("hour", hour(col("ts"))))

    # Áp dụng hàm sửa lỗi font cho cột bài hát và nghệ sĩ
    if topic in ["listen_events", "page_view_events"]:
        stream = (stream
                .withColumn("song", string_decode("song"))
                .withColumn("artist", string_decode("artist")))

    return stream

# 4. Hàm xả dữ liệu phân tầng xuống HDFS
def create_file_write_stream(stream, storage_path, checkpoint_path, trigger="10 seconds", output_mode="append", file_format="json"):
    return (stream
            .writeStream
            .format(file_format)
            .partitionBy("year", "month", "day", "hour") # Tính năng chia ngăn dữ liệu theo thời gian để tăng tốc truy vấn sau này
            .option("path", storage_path)
            .option("checkpointLocation", checkpoint_path)
            .trigger(processingTime=trigger)
            .outputMode(output_mode))