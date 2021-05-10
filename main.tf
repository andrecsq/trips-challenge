terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.66.1"
    }
  }
}

locals {
  credentials_data = jsondecode(file("${path.module}/credentials.json"))
  project          = local.credentials_data.project_id
  region           = "us-central1"
  zone             = "us-central1-c"
  pubsub_topic_id  = "trips"
  cf_name          = "trips_to_bigquery"
  cf_entry_point   = "process_message"
  bq_dataset_id    = "GIS_DATA"
  bq_table_id      = "trips"
}

provider "google" {

  credentials = file("credentials.json")

  project = local.project
  region  = local.region
  zone    = local.zone
}

# ENABLE NECESSARY APIs

resource "google_project_service" "su" {
  project = local.project
  service = "serviceusage.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "crm" {
  project = local.project
  service = "cloudresourcemanager.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "cf" {
  project = local.project
  service = "cloudfunctions.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "cb" {
  project = local.project
  service = "cloudbuild.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

# Create PubSub topic

resource "google_pubsub_topic" "trips" {
  name = local.pubsub_topic_id
}

# Create BigQuery table

resource "google_bigquery_dataset" "gis_dataset" {
  dataset_id = local.bq_dataset_id
  location   = "US"
}

resource "google_bigquery_table" "default" {
  dataset_id          = google_bigquery_dataset.gis_dataset.dataset_id
  table_id            = local.bq_table_id
  deletion_protection = false

  time_partitioning {
    type                     = "HOUR"
    field                    = "datetime"
    require_partition_filter = true
  }

  clustering = ["origin_coord", "destination_coord"]

  schema = <<EOF
[
  {
    "name": "region",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "origin_coord",
    "type": "GEOGRAPHY",
    "mode": "NULLABLE"
  },
  {
    "name": "destination_coord",
    "type": "GEOGRAPHY",
    "mode": "NULLABLE"
  },
  {
    "name": "datetime",
    "type": "DATETIME",
    "mode": "NULLABLE"
  },
  {
    "name": "datasource",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF

}


# Compress and upload Cloud Function code

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.module}/cf_code/"
  output_path = "/tmp/trips-function-code.zip"
}

resource "google_storage_bucket" "bucket" {
  name = "${local.project}-trips-function-code"
}

resource "google_storage_bucket_object" "zip" {
  # Append file MD5 to force bucket to be recreated
  name   = "source.zip#${data.archive_file.source.output_md5}"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.source.output_path
}

# Create Cloud Function to process messages

resource "google_cloudfunctions_function" "function" {
  name    = local.cf_name
  runtime = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.zip.name
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.trips.id
  }
  entry_point = local.cf_entry_point
  environment_variables = {
    "PROJECT_ID"    = local.project
    "BQ_DATASET_ID" = local.bq_dataset_id
    "BQ_TABLE_ID"   = local.bq_table_id
  }
}
