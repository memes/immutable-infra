# Export the URL for the web service
output "web_service_url" {
  value = "${format("http://%s/", google_compute_global_forwarding_rule.web.ip_address)}"
}