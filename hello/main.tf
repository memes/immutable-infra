# Creates a simple GCE application as a demo

# Setup Google provider
provider "google" {
    version = "~> 1.17"
    project = "${var.project_id}"
    region = "${var.region}"
    zone = "${var.zone}"
}

data "template_file" "startup-script" {
    count = "${var.instance_count}"
    template = "${file("./setup.sh")}"

    vars {
        host = "${format("web-%02d", count.index)}"
    }
}

resource "google_compute_instance" "web" {
    count = "${var.instance_count}"
    name = "${format("web-%02d", count.index)}"
    machine_type = "n1-standard-1"
    allow_stopping_for_update = true
    tags = ["web"]

    metadata {
        startup-script = "${data.template_file.startup-script.*.rendered[count.index]}"
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

    instances = ["${google_compute_instance.web.*.self_link}"]

    named_port {
        name = "http"
        port = "80"
    }
}

resource "google_compute_health_check" "web" {
    name = "web-health-check"
    timeout_sec = 1
    check_interval_sec = 1
    tcp_health_check {
        port = "80"
    }
}

resource "google_compute_backend_service" "web" {
    name = "web-service"
    port_name = "http"
    protocol = "HTTP"
    enable_cdn = false
    timeout_sec = 3
    

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

    source_ranges = ["0.0.0.0/0"]
    target_tags   = ["web"]
}
