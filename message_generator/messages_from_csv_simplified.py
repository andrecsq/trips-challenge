import pandas as pd
import time
import json
from google.cloud import pubsub_v1

project_id = "argon-triode-138719"
topic_id = "trips"

publisher = pubsub_v1.PublisherClient.from_service_account_file("../credentials.json")
topic_path = publisher.topic_path(project_id, topic_id)

print(f"Topic path: {topic_path}")

trips_df = pd.read_csv("example_trips.csv")
trips = trips_df.to_dict("records")
print(f"Found {len(trips)} rows.")

print("Publishing to PubSub...")
for trip in trips:
    trip["datetime"] = trip["datetime"].replace(" ", "T")  # Hack to work in BigQuery

    data = json.dumps(trip)
    print(f"trying to publish {data}")

    publisher.publish(topic_path, data.encode("utf-8"))
