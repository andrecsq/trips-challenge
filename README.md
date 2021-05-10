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

## The architecture

I went for the GCP services that I am more familiar with, enabling a full serverless architecture. 
![challenge_architeture](https://user-images.githubusercontent.com/5351051/117597604-4df47880-b11c-11eb-95a5-d6ddc3d01c9a.png)

For an Open Source solution, I would think about using RabbitMQ for messaging, Knative for Functions and Druid for Data Warehousing. 

The data will be accessed by the Data Scientists by querying the BigQuery table. GCP has great documetnation for manipulating GIS data: https://cloud.google.com/bigquery/docs/gis

## How to create the Infrastructure

Install Terraform in your system of preference: https://www.terraform.io/downloads.html

Navigate to your folder of preference

Clone this repo 
```
git clone https://github.com/andrecsq/terraform_test.git
```

Navigate to its folder
```
cd terraform_test
```

Set up your GCP account as per the Terraform documentation: ![Link](https://learn.hashicorp.com/tutorials/terraform/google-cloud-platform-build?in=terraform/gcp-get-started)

Move the created Service Account JSON on the repo's root folder as `credentials.json`

Check if the local variables in the `main.tf` file are appropriate. (TODO: put `locals` on another file)

Initialize terraform
```
terraform init
```

Create infraestructure
```
terraform apply
```

Now you can publish messages to the PubSub topic `pubsub_topic_id` (default value `trips`) and have these topics processed and loaded to the BigQuery table (default `GIS_DATA.trips`)

## How to publish a message to PubSub
It cannot be done directly via HTTP. Guide here: https://cloud.google.com/pubsub/docs/publisher

## Mandatory features

- [x] There must be an automated process to ingest and store the data.
- [x] Trips with similar origin, destination, and time of day should be grouped together.
- [x] Develop a way to obtain the weekly average number of trips for an area, defined by a bounding box (given by coordinates) or by a region.
- [ ] Develop a way to inform the user about the status of the data ingestion without using a polling solution.
- [x] The solution should be scalable to 100 million entries. It is encouraged to simplify the data by a data model. Please add proof that the solution is scalable.
- [x] Use a SQL database.

I grouped the data by using BigQuery's partitioning (time of day - hour) and clustering (origin, destination). Time of day filter is mandatory, but the clustering filter is not.

## Known Limitations

- **Need to replace `' '` to `'T'` on the `datetime` field before publishing a message**
- PubSub can have a schema. It is without a schema because Terraform doesn't currently support it.
- PubSub doesn't guarantee deduplication, so messages on BigQuery will have duplicated data with high volume. 
- There isn't a centralized way to monitor messages being processed. But each service can be monitored individually via Logs Explorer. These logs are temporary, but it is possible to create a sink from any service's logs to BigQuery.
- BigQuery's clustering only works in the order of the clustered fields, which is first origin and destination second. e.g. if you filter in the query by destination and not by origin the clustering won't work.


