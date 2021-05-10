import pandas as pd
import time
import json
from google.cloud import pubsub_v1

project_id = "argon-triode-138719"
topic_id = "trips"

publisher = pubsub_v1.PublisherClient.from_service_account_file("../credentials.json")
topic_path = publisher.topic_path(project_id, topic_id)
futures = dict()

print(topic_path)


def get_callback(f, data):
    def callback(f):
        try:
            print(f.result())
            futures.pop(data)
        except:  # noqa
            print("Please handle {} for {}.".format(f.exception(), data))

    return callback


trips_df = pd.read_csv("example_trips.csv")
trips = trips_df.to_dict("records")
print(f"Found {len(trips)} rows.")

print("Publishing to PubSub...")
for trip in trips:
    trip["datetime"] = trip["datetime"].replace(" ", "T")  # Hack to work in BigQuery
    data = json.dumps(trip)
    print(f"trying to publish {data}")
    futures.update({data: None})
    # When you publish a message, the client returns a future.
    future = publisher.publish(topic_path, data.encode("utf-8"))
    futures[data] = future
    # Publish failures shall be handled in the callback function.
    future.add_done_callback(get_callback(future, data))

# Wait for all the publish futures to resolve before exiting.
while futures:
    time.sleep(5)

print(f"Published messages with error handler to {topic_path}.")
