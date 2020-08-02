variable "app_name" {
  type = string
}

variable "google_compute_network_id" {
  type = string
}

variable "google_service_networking_connection_private_vpc_connection" {
  type = any
}

variable "cloud_sql_user_name" {
  type = string
}

variable "cloud_sql_user_password" {
  type = string
}