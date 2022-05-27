#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
"""
This is an example DAG which uses SparkKubernetesOperator and SparkKubernetesSensor.
In this example, we create two tasks which execute sequentially.
The first task is to submit sparkApplication on Kubernetes cluster(the example uses spark-pi application).
and the second task is to check the final state of the sparkApplication that submitted in the first state.

Spark-on-k8s operator is required to be already installed on Kubernetes
https://github.com/GoogleCloudPlatform/spark-on-k8s-operator
"""

import yaml
from datetime import datetime, timedelta

# [START import_module]
# The DAG object; we'll need this to instantiate a DAG
from airflow import DAG

# Operators; we need this to operate!
from airflow.operators.python_operator import PythonOperator
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import SparkKubernetesOperator
from airflow.providers.cncf.kubernetes.sensors.spark_kubernetes import SparkKubernetesSensor

# [END import_module]

# [START auxiliary functions]


def get_new_app_manifest(
    template_path: str,
    table_name: str
):
    with open(template_path, "r") as template:
        try:
            template_content = yaml.safe_load(template)
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

# get_new_mainfest = PythonOperator(
#     dag=dag,
#     task_id="get_new_manifest",
#     python_callable=get_new_app_manifest,
#     op_kwargs={
#         "template_path": "apps/orchestration/airflow/dags/etl-bronze/etl_bronze_app_template.yaml",
#         "table_name": "order_products"
#     }
# )

t1 = SparkKubernetesOperator(
    task_id='etl_bronze_submit',
    namespace="processing",
    # application_file="etl_bronze_app.yaml",
    application_file=get_new_app_manifest(
        template_path="/opt/airflow/dags/repo/apps/orchestration/airflow/dags/etl-bronze/etl_bronze_app_template.yaml",
        table_name="order_products"
    ),
    kubernetes_conn_id="kubernetes_cluster",
    do_xcom_push=True,
    dag=dag,
)

t2 = SparkKubernetesSensor(
    task_id='etl_bronze_monitor',
    namespace="processing",
    kubernetes_conn_id="kubernetes_cluster",
    application_name="{{ task_instance.xcom_pull(task_ids='etl_bronze_submit')['metadata']['name'] }}",
    dag=dag,
)
t1 >> t2