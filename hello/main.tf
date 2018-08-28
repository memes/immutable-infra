# Creates a simple GCE application as a demo

# Setup Google provider
provider "google" {
    version = "~> 1.17"
    project = "${var.project_id}"
    region = "${var.region}"
    zone = "${var.zone}"
}

data "local_file" "startup-script" {
    filename = "setup.sh"
}

resource "google_compute_instance" "web" {
    name = "web"
    machine_type = "n1-standard-1"
    allow_stopping_for_update = true
    tags = ["web"]

    metadata {
        startup-script = "${data.local_file.startup-script.content}"
    }

    boot_disk {
        initialize_params {
            image = "projects/debian-cloud/global/images/family/debian-9"
        }
    }

    network_interface {
        network = "default"

        access_config {

        }
    }

    service_account {
        scopes = ["cloud-platform"]
    }
}

resource "google_compute_global_address" "web" {
    name = "web-external-ip"
}

resource "google_compute_instance_group" "web" {
    name = "web-unmanaged-group"
    zone = "${var.zone}"

    instances = ["${google_compute_instance.web.self_link}"]

    named_port {
        name = "http"
        port = "80"
    }
}

resource "google_compute_health_check" "web" {
    name = "web-health-check"
    tcp_health_check {
        port = "80"
    }
}

resource "google_compute_backend_service" "web" {
    name = "web-service"
    port_name = "http"
    protocol = "HTTP"
    enable_cdn = false

    backend {
        group = "${google_compute_instance_group.web.self_link}"
    }

    health_checks = ["${google_compute_health_check.web.self_link}"]
}

resource "google_compute_url_map" "web" {
    name            = "web-url-map"
    default_service = "${google_compute_backend_service.web.self_link}"
}

resource "google_compute_target_http_proxy" "web" {
    name    = "web-proxy"
    url_map = "${google_compute_url_map.web.self_link}"
}

resource "google_compute_global_forwarding_rule" "web" {
    name       = "web-global-fwd-rule"
    target     = "${google_compute_target_http_proxy.web.self_link}"
    ip_address = "${google_compute_global_address.web.address}"
    port_range = "80"
}

resource "google_compute_firewall" "allow-web" {
    name    = "allow-web"
    network = "default"
    allow {
        protocol = "tcp"
        ports    = ["80"]
    }

    # These are the IP address of Google's global loadbalancers
    source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
    target_tags   = ["web"]
}
