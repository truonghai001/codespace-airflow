from datetime import datetime
from airflow.sdk import dag, task


@dag(
    dag_id="first_codespace_dag",
    schedule="@daily",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["codespace", "tutorial"],
)
def first_codespace_dag():
    @task
    def extract():
        return {"users": 42, "status": "ok"}

    @task
    def transform(data: dict):
        return f"Processed {data['users']} users with status: {data['status']}"

    @task
    def load(summary: str):
        print(f"Final result: {summary}")

    raw_data = extract()
    summary_text = transform(raw_data)
    load(summary_text)


first_codespace_dag()
