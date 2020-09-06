#
# public(外部公開), prvate(外部非公開） 用の VPC network を２つ作成し，それぞれにサブネットを配置する
#

# public 用 vpc を作成
resource "google_compute_network" "public_network" {
  name = "${var.app_name}-public-network"
  auto_create_subnetworks = false
}

# private 用 vpc を作成
resource "google_compute_network" "private_network" {
  name = "${var.app_name}-private-network"
  auto_create_subnetworks = false
}

# 内部 ip アドレスからの受信をすべて許可するFirewall を設定
# デフォルトでは 最も低い優先度で INBOUNDはすべて拒否, OUTBOUNDはすべて許可のルールが存在するので，それよりも優先度の高いルールで INBOUNDを許可する
resource "google_compute_firewall" "public_network_allow_ingress_internal" {
  name = "${var.app_name}-allow-ingress-internal"
  network = google_compute_network.public_network.self_link
  source_ranges = ["10.0.0.0/8"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports = ["0-65535"]
  }
}


# vpcピアリングを設定し VPC間で private ip での接続を可能にする
resource "google_compute_network_peering" "pub_priv_peering" {
  name = "${var.app_name}-pub-priv-peering"
  network = google_compute_network.public_network.self_link
  peer_network = google_compute_network.private_network.self_link
}
resource "google_compute_network_peering" "priv_pub_peering" {
  name = "${var.app_name}-priv-pub-peering"
  network = google_compute_network.private_network.self_link
  peer_network = google_compute_network.public_network.self_link
}


# 各VPCネットワーク 内にサブネットを作成する
# VPCピアリングをしているので，それぞれのサブネットの ip レンジは被ってはいけない
resource "google_compute_subnetwork" "public_subnet" {
  name = "${var.app_name}-public-subnet"
  ip_cidr_range = "10.10.10.0/24"
  network = google_compute_network.public_network.self_link]
  region = "asia-northeast1"
}
resource "google_compute_subnetwork" "private_subnet" {
  name = "${var.app_name}-private-subnet"
  ip_cidr_range = "10.10.20.0/24"
  network = google_compute_network.private_network.self_link]
  region = "asia-northeast1"
}



# 限定公開ネットワークからGoogle APIs、Container RegistryにアクセスするためのDNS設定を追加します
# ネットワークをいつ限定公開にしたのか？？
resource "google_dns_record_set" "google_apis_cname" {
  project      = var.project
  managed_zone = "google-apis"
  name         = "*.${google_dns_managed_zone.google_apis.dns_name}"
  type         = "CNAME"
  ttl          = 300

  rrdatas      = ["restricted.googleapis.com."]
}

resource "google_dns_record_set" "google_apis_a" {
  project      = var.project
  managed_zone = "google-apis"
  name         = "restricted.googleapis.com."
  type         = "A"
  ttl          = 300

  rrdatas      = ["199.36.153.4","199.36.153.5","199.36.153.6","199.36.153.7"]
}

resource "google_dns_managed_zone" "google_apis" {
  project    = var.project
  name       = "google-apis"
  dns_name   = "googleapis.com."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = var.my_priv_nw_url
    }
  }
}

