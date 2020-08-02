# vpc を作成
resource "google_compute_network" "main" {
  name = "${var.app_name}-network"
  auto_create_subnetworks = false
}

# vpc 内にサブネットを作成
resource "google_compute_subnetwork" "main" {
  name = "${var.app_name}-subnetwork"
  ip_cidr_range = "10.30.0.0/16"
  network = google_compute_network.main.name
  description = "part2 の webserver用"
  region = "asia-northeast1"
}

# vpc 全体に Firewall Rule を設定 (vpc 内のサブネットワークごとの適用は出来ないので注意)
# compute instance に設定した tags を用いてネットワーク内のどのインスタンスに適用するかどうかを指定することもできる, デフォルトは全てに適用
resource "google_compute_firewall" "main" {
  name = "${var.app_name}-firewall"
  network = google_compute_network.main.name

  # 設定を適用するトラフィックの方向を指定 (デフォルトはINGRESS)
  direction = "INGRESS"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = ["22", "80", "443"]
  }
}

# CloudSQLに割り当てる private ip レンジを作成する
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.app_name}-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

# VPC の private ip レンジを VPCピアリングに用いることを宣言
# VPC 内の指定した ip レンジは CloudSQL等のグローバルリソースの ip に割り当てられることになるので他のローカルリソースには使えなくなる
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.name
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}