import yaml
from datetime import datetime, timedelta

# [START import_module]
# The DAG object; we'll need this to instantiate a DAG
from airflow import DAG

# Operators; we need this to operate!
from airflow.operators.python_operator import PythonOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import SparkKubernetesOperator
from airflow.providers.cncf.kubernetes.sensors.spark_kubernetes import SparkKubernetesSensor

# [END import_module]

# [START auxiliary functions]

tables = [
    "order_products",
    "orders",
    "products",
    "restaurants",
    "users",
]


def get_new_app_manifest(
    template_path: str,
    table_name: str
):
    with open(template_path, "r") as template:
        try:
            template_content = yaml.safe_load(template)
            # Setting spark application name
            template_content["metadata"]["name"] = f"{table_name}-landing-to-bronze"
            # Setting table name
            template_content["spec"]["driver"]["envVars"]["TABLE_NAME"] = table_name
            new_template_content = yaml.dump(template_content)
        except yaml.YAMLError as exc:
            print(exc)
        template.close()

    return new_template_content

# [END auxiliary functions]


dag = DAG(
    'etl_bronze',
    default_args={'max_active_runs': 1},
    description='submit elt_bronze_app as sparkApplication on kubernetes',
    schedule_interval=timedelta(days=1),
    start_date=datetime(2021, 1, 1),
    catchup=False,
)

start_task = DummyOperator(task_id="start")

for table in tables:
    table = table.replace("_", "-")
    from_landning_to_bronze = SparkKubernetesOperator(
        task_id=f'{table}_from_landing_to_bronze',
        namespace="processing",
        application_file=get_new_app_manifest(
            template_path="/opt/airflow/dags/repo/apps/orchestration/airflow/dags/etl-bronze/etl_bronze_app_template.yaml",
            table_name=table
        ),
        kubernetes_conn_id="kubernetes_cluster",
        do_xcom_push=True,
        dag=dag,
    )

    bronze_monitor = SparkKubernetesSensor(
        task_id=f'{table}_bronze_monitor',
        namespace="processing",
        kubernetes_conn_id="kubernetes_cluster",
        application_name=f"{{ task_instance.xcom_pull(task_ids='{table}_from_landing_to_bronze')['metadata']['name'] }}",
        dag=dag,
    )

    start_task >> from_landning_to_bronze >> bronze_monitor
