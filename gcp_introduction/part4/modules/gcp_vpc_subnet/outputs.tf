output "google_compute_network_id" {
  value = google_compute_network.main.id
}

output "google_compute_network_name" {
  value = google_compute_network.main.name
}

output "google_compute_sub_network_name" {
  value = google_compute_subnetwork.main.name
}

output "google_service_networking_connection_private_vpc_connection" {
  value = google_service_networking_connection.private_vpc_connection
}