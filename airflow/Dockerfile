FROM apache/airflow:2.7.0-python3.10
USER root
# Cài đặt thư viện hệ thống cho PyHive
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         libsasl2-dev libsasl2-modules \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
USER airflow
COPY requirements.txt /
# Đã xóa chữ apache-airflow ở lệnh này để tránh nó check lại phiên bản gây lỗi
RUN pip install --no-cache-dir -r /requirements.txt