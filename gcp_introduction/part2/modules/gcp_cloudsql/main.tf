# CloudSQL に private であることを示すための name をつけたいが，name は一度付けると変えられない，削除しても１週間は再利用できない
# ので，name の末尾にランダム文字列を付ける
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# CloudSQL の DBインスタンスを作成 (内部に DB, Table を作成する)
resource "google_sql_database_instance" "main" {
  name = "${var.app_name}-private-instance-${random_id.db_name_suffix.hex}"
  database_version = "MYSQL_5_7"
  region = "asia-northeast1"

  # CloudSQL が VPC 内に確保しした private ip を利用するように設定
  depends_on = [var.google_service_networking_connection_private_vpc_connection]

  settings {
    tier = "db-n1-standard-1"
    availability_type = "ZONAL" # REGIONAL とするとフェイルオーバーが作成される？
    disk_size = 10
    disk_type = "PD_SSD"

    ip_configuration {
      ipv4_enabled = true # global ip の付与の有無，デフォルトは true なので注意, private にしたい場合はVPC等の事前準備が必要
                          # true にしつつ private_network も設定すると public ip, private ip 両方設定できる
      private_network = var.google_compute_network_id
      require_ssl = false
    }

    backup_configuration {
      enabled = false
    }
  }
}

# CloudSQL ではインスタンス作成時に自動的に パスワードなし root ユーザーが作成されるが, Terraform 側でインスタンス作成時にこれを削除している
# DB ユーザーは以下 resource を用いて明示的に作成しなくてはならない
resource "google_sql_user" "main" {
  instance = google_sql_database_instance.main.name
  name     = var.cloud_sql_user_name
  password = var.cloud_sql_user_password
}