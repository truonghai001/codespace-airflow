#!/usr/bin/env bash
set -e

WORKSPACE_DIR="$(pwd)"
export AIRFLOW_HOME="$HOME/airflow"
mkdir -p "$AIRFLOW_HOME"

if [ -n "$POSTGRESQL_URL" ]; then
    export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=$(echo "$POSTGRESQL_URL" | sed -E 's|^postgres(ql)?://|postgresql+psycopg2://|')
fi

if ! pgrep -f "airflow standalone" > /dev/null 2>&1; then
    . "$WORKSPACE_DIR/airflow_env/bin/activate"
    nohup airflow standalone > "$AIRFLOW_HOME/standalone.log" 2>&1 &
    echo "Airflow 3 running in background. View logs: tail -f $AIRFLOW_HOME/standalone.log"
else
    echo "Airflow 3 is already running."
fi
