# Export the URL for the web service
output "web_service_url" {
  value = "${format("https://%s/", replace(google_dns_record_set.infra.name, "/.$/", ""))}"
}