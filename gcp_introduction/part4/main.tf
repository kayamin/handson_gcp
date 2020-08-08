module "vpc_subnet" {
  source = "./modules/gcp_vpc_subnet"
  app_name = var.app_name
}

module "kubernetes_engine" {
  source = "./modules/gcp_kubernetes_engine"
  app_name = var.app_name
  region = var.region
  google_compute_network_name = module.vpc_subnet.google_compute_network_name
  google_compute_sub_network_name = module.vpc_subnet.google_compute_sub_network_name
}