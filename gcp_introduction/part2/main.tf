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



# GCE のインスタンスを作成
resource "google_compute_instance" "main" {
  name = "${var.app_name}-compute-instance"
  machine_type = "n1-standard-1"
  zone = "asia-northeast1-a"

  # 永続ディスクについての設定
  boot_disk {
    auto_delete = true # インスタンス削除時に diskも削除する
    initialize_params {
      image = "debian-cloud/debian-9" # インスタンスで用いるイメージを指定
      size = 10 # GB単位で容量指定
      type = "pd-standard"
    }
  }

  # ローカルディスクについての設定
  scratch_disk {
    interface = "SCSI"
  }

  # インスタンスを作成するネットワークを指定
  network_interface {
    network = google_compute_network.main.name # VPC を指定
    subnetwork = google_compute_subnetwork.main.name # サブネットワークを指定

    # ネットワークインターフェースに割り当てる global ip を指定
    # 空 で指定すると ephemeral ip を割り当てることが可能
//    access_config {
//      # 割り当てる global ip を指定
//      # global ip は google_compute_address リソースで事前に作成する
//      //nat_ip = ""
//    }
  }

  # GCE インスタンスに付与するサービスアカウントを宣言
  # 既存のものを指定もできる?し，ここで各種サービスへの権限を定義することも可能
  # scopes で定義可能な権限の種類は現在はあまり多くない模様．詳細に設定したければ別途サービスアカウントを作ってそちらで指定するべきということか
  service_account {
    scopes = ["storage-rw", "sql-admin"] # CloudStorage, Cloud SQL の権限を付与
  }

  # インスタンス起動時に実行するスクリプトを指定
  # 起動スクリプトの実行結果はインスタンスにsshして確認可能 https://cloud.google.com/compute/docs/startupscript?hl=ja
  # StackDriver Logging を 付与したサービスアカウントのスコープに含めていれば，実行ログの Logging への書き出しも行ってくれる
  metadata_startup_script = file("./setup.sh")
}