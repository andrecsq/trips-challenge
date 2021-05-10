import base64
import json
import os
from google.cloud import bigquery


def process_message(event, context):
    raw_message = base64.b64decode(event["data"]).decode("utf-8")

    message_dict = json.loads(raw_message)

    project_id = os.environ.get("PROJECT_ID")
    bq_dataset_id = os.environ.get("BQ_DATASET_ID")
    bq_table_id = os.environ.get("BQ_TABLE_ID")

    table_id = f"{project_id}.{bq_dataset_id}.{bq_table_id}"
    rows_to_insert = [message_dict]

    client = bigquery.Client()
    errors = client.insert_rows_json(
        table_id, rows_to_insert, row_ids=[None] * len(rows_to_insert)
    )  # Make an API request.
    if errors == []:
        print("Row added.")
    else:
        print("Error: {}".format(errors))
