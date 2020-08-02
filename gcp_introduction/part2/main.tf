module "vpc_subnet" {
  source = "./modules/gcp_vpc_subnet"
  app_name = var.app_name
}

module "compute_engine" {
  source = "./modules/gcp_compute_engine"
  app_name = var.app_name
  google_compute_network_name = module.vpc_subnet.google_compute_network_name
  google_compute_sub_network_name = module.vpc_subnet.google_compute_sub_network_name
}

module "cloud_sql" {
  source = "./modules/gcp_cloudsql"
  app_name = var.app_name
  google_compute_network_id = module.vpc_subnet.google_compute_network_id
  google_service_networking_connection_private_vpc_connection = module.vpc_subnet.google_service_networking_connection_private_vpc_connection
}