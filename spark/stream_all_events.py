import os
from pyspark.sql import SparkSession
from streaming_functions import *
from schema import schema

# 1. Khai báo 3 Topics cần hút từ Kafka
LISTEN_EVENTS_TOPIC = "listen_events"
PAGE_VIEW_EVENTS_TOPIC = "page_view_events"
AUTH_EVENTS_TOPIC = "auth_events"

# 2. Cấu hình lại Trạm trung chuyển Kafka (Trỏ về mạng nội bộ Docker)
KAFKA_PORT = "29092"
KAFKA_ADDRESS = "broker"

# 3. Cấu hình Kho chứa HDFS
HDFS_STORAGE_PATH = "hdfs://namenode:9000/datalake"

# 4. Khởi tạo Spark trực tiếp bằng PySpark
spark = SparkSession.builder \
    .appName("Eventsim_Stream_HDFS") \
    .master("spark://spark-master:7077") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")
spark.streams.resetTerminated()

print(">>> [START] Đang cắm ống hút vào 3 topics của Kafka...")

# --- LUỒNG 1: LISTEN EVENTS ---
listen_events = create_kafka_read_stream(
    spark, KAFKA_ADDRESS, KAFKA_PORT, LISTEN_EVENTS_TOPIC)
listen_events = process_stream(
    listen_events, schema[LISTEN_EVENTS_TOPIC], LISTEN_EVENTS_TOPIC)

# --- LUỒNG 2: PAGE VIEW EVENTS ---
page_view_events = create_kafka_read_stream(
    spark, KAFKA_ADDRESS, KAFKA_PORT, PAGE_VIEW_EVENTS_TOPIC)
page_view_events = process_stream(
    page_view_events, schema[PAGE_VIEW_EVENTS_TOPIC], PAGE_VIEW_EVENTS_TOPIC)

# --- LUỒNG 3: AUTH EVENTS ---
auth_events = create_kafka_read_stream(
    spark, KAFKA_ADDRESS, KAFKA_PORT, AUTH_EVENTS_TOPIC)
auth_events = process_stream(
    auth_events, schema[AUTH_EVENTS_TOPIC], AUTH_EVENTS_TOPIC)

print(">>> [PROCESSING] Đang xả dữ liệu xuống kho HDFS...")

# 5. Tạo 3 vòi xả
listen_events_writer = create_file_write_stream(
    listen_events,
    storage_path=f"{HDFS_STORAGE_PATH}/{LISTEN_EVENTS_TOPIC}",
    checkpoint_path=f"{HDFS_STORAGE_PATH}/checkpoint/{LISTEN_EVENTS_TOPIC}",
    trigger="10 seconds",
    file_format="json" 
)

page_view_events_writer = create_file_write_stream(
    page_view_events,
    storage_path=f"{HDFS_STORAGE_PATH}/{PAGE_VIEW_EVENTS_TOPIC}",
    checkpoint_path=f"{HDFS_STORAGE_PATH}/checkpoint/{PAGE_VIEW_EVENTS_TOPIC}",
    trigger="10 seconds",
    file_format="json"
)

auth_events_writer = create_file_write_stream(
    auth_events,
    storage_path=f"{HDFS_STORAGE_PATH}/{AUTH_EVENTS_TOPIC}",
    checkpoint_path=f"{HDFS_STORAGE_PATH}/checkpoint/{AUTH_EVENTS_TOPIC}",
    trigger="10 seconds",
    file_format="json"
)

# 6. Mở cả 3 vòi xả cùng một lúc
listen_events_writer.start()
auth_events_writer.start()
page_view_events_writer.start()

print(">>> [RUNNING] Dây chuyền đang chạy ngầm. Bấm Ctrl+C trên Terminal để dừng.")
spark.streams.awaitAnyTermination()