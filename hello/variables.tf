variable "project_id" {
    type = "string"
    description = <<EOF
The unique project id that will contain these resources. Defaults to `memes-sandbox`.
EOF
    default = "ocgcp-projects"
}

variable "region" {
    type = "string"
    description = "The region to use by default. Defaults to `us-west1`."
    default = "us-west1"
}

variable "zone" {
    type = "string"
    description = "The zone that the web server will be deployed to. Defaults to `us-west1-a`."
    default = "us-west1-a"
}

variable "instance_count" {
    type = "string"
    description = "The number of web server instances to launch. Defaults to 1."
    default = "1"
}