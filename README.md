# Trips Challenge

Build an automatic process to ingest data on an on-demand basis. The data represents trips taken by different vehicles, and include a city, a point of origin and a destination.
Example data point:
```json
{
	"region": "Prague",
	"origin_coord": "POINT (14.4973794438195 50.00136875782316)",
	"destination_coord": "POINT (14.43109483523328 50.04052930943246)",
	"datetime": "2018-05-28 9:03:40",
	"datasource": "funny_car"
}
```

# The architecture

I went for the GCP services that I am more familiar with, enabling a full serverless architecture. 
![challenge_architeture](https://user-images.githubusercontent.com/5351051/117597604-4df47880-b11c-11eb-95a5-d6ddc3d01c9a.png)

For an Open Source solution, I would think about using RabbitMQ for messaging, Knative for Functions and Druid for Data Warehousing. 

# How to publish a message to PubSub
It cannot be done via HTTP. Guide here: https://cloud.google.com/pubsub/docs/publisher

# How to create the Infrastructure

Install Terraform in your system of preference: https://www.terraform.io/downloads.html

Clone this repo 
```bash
git clone 
```
