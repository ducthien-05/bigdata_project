from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator

default_args = {
    'owner': 'team_2',
    'depends_on_past': False,         
    'retries': 1,                     
    'retry_delay': timedelta(minutes=2), 
}

with DAG(
    dag_id='musicify_dag',
    default_args=default_args,
    description='Luồng Data Pipeline tự động hóa từ Spark đến DBT',
    schedule_interval='@daily',       
    start_date=datetime(2026, 5, 29), 
    catchup=False,                    
    tags=['dbt', 'spark', 'powerbi'],
) as dag:

    start_pipeline = EmptyOperator(task_id='START_PIPELINE')
    end_pipeline = EmptyOperator(task_id='END_PIPELINE')

    spark_ingestion = BashOperator(
        task_id='spark_pull_kafka_to_hdfs',
        bash_command='echo "Đang giả lập việc Spark submit job kéo dữ liệu từ Kafka xuống HDFS..." && sleep 5'
    )

    dbt_seed_task = BashOperator(
        task_id='dbt_seed_reference_data',
        bash_command='cd /dbt/musicify && dbt seed --profiles-dir /dbt/musicify'
    )
    
    dbt_run_dims = BashOperator(
        task_id='dbt_build_dimensions',
        bash_command='cd /dbt/musicify && dbt run --profiles-dir /dbt/musicify --select dim_artists dim_songs dim_location dim_users dim_datetime'
    )

    dbt_run_fact = BashOperator(
        task_id='dbt_build_fact_streams',
        bash_command='cd /dbt/musicify && dbt run --profiles-dir /dbt/musicify --select fact_streams --full-refresh'
    )

    dbt_run_wide = BashOperator(
        task_id='dbt_build_wide_streams',
        bash_command='cd /dbt/musicify && dbt run --profiles-dir /dbt/musicify --select wide_streams'
    )

    powerbi_refresh = BashOperator(
        task_id='trigger_powerbi_api',
        bash_command='echo "Giả lập bắn REST API sang máy chủ Microsoft Power BI..." && sleep 3'
    )

    (
        start_pipeline 
        >> spark_ingestion 
        >> dbt_seed_task
        >> dbt_run_dims 
        >> dbt_run_fact 
        >> dbt_run_wide
        >> powerbi_refresh
        >> end_pipeline
    )