variable "app_name" {
  type = string
  default = "webserver"
}

variable "region" {
  type = string
  default = "asia-northeast1"
}

variable "google_compute_network_name" {
  type = string
}

variable "google_compute_sub_network_name" {
  type = string
}