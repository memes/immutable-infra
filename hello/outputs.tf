# Export the URL for the web service
output "web_service_url" {
  value = "${format("https://%s/", google_compute_global_forwarding_rule.https.ip_address)}"
}