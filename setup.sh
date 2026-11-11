#!/usr/bin/env bash
set -e

WORKSPACE_DIR="$(pwd)"

if [ -z "$POSTGRESQL_URL" ]; then
    echo "Error: POSTGRESQL_URL secret is not set. Add it in GitHub Codespaces settings."
    exit 1
fi

# Convert postgres:// or postgresql:// to postgresql+psycopg2:// for SQLAlchemy
SQLALCHEMY_URL=$(echo "$POSTGRESQL_URL" | sed -E 's|^postgres(ql)?://|postgresql+psycopg2://|')
export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="$SQLALCHEMY_URL"

# 1. Recreate virtual environment if missing or broken after container rebuild
if [ ! -x "$WORKSPACE_DIR/airflow_env/bin/python" ]; then
    rm -rf "$WORKSPACE_DIR/airflow_env"
    python3 -m venv "$WORKSPACE_DIR/airflow_env"
fi

. "$WORKSPACE_DIR/airflow_env/bin/activate"
python -m pip install --upgrade pip
python -m pip install "apache-airflow[postgres]>=3.0.0" psycopg2-binary

# 2. Configure Airflow permanently in airflow.cfg
export AIRFLOW_HOME="$HOME/airflow"
mkdir -p "$WORKSPACE_DIR/dags"

if [ ! -f "$AIRFLOW_HOME/airflow.cfg" ]; then
    airflow config list > /dev/null
fi

sed -i "s|^sql_alchemy_conn = .*|sql_alchemy_conn = $SQLALCHEMY_URL|" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s|^executor = .*|executor = LocalExecutor|" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s|^load_examples = .*|load_examples = False|" "$AIRFLOW_HOME/airflow.cfg"
sed -i "s|^dags_folder = .*|dags_folder = $WORKSPACE_DIR/dags|" "$AIRFLOW_HOME/airflow.cfg"

# 3. Verify connection, migrate remote database, and parse DAGs
airflow db check
airflow db migrate
airflow dags reserialize

echo "Airflow 3 setup complete with external PostgreSQL!"
