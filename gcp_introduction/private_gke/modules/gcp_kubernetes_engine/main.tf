# GKEのノードに割り当てるサービスアカウントを作成
resource "google_service_account" "gke_node_pool" {
  account_id = "${var.app_name}-gke-node-pool"
  display_name = "${var.app_name}-gke-node-pool"
  description = "A service account for GKE node"
}

# サービスアカウントに必要最低限の IAMロール（権限）を付与
# １リソースで１つのロールしか紐付けられないので for_each でまとめて記述するように工夫
resource "google_project_iam_member" "gke_node_pool" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/datastore.owner",
    "roles/storage.objectViewer"])

  role = each.value
  member = "serviceAccount:${google_service_account.gke_node_pool.email}"
}

# GKE クラスタを定義
resource "google_container_cluster" "main" {
  name = "${var.app_name}-gke-cluster"
  # region, zone どちらも指定可能, zone を指定した場合には cluster will be a zonal cluster with a single cluster master.
  # region を指定した場合には the cluster will be a regional cluster with multiple masters spread across zones in the region, and with default node locations in those zones as well
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # クラスタを作成するVPC, subnet を指定
  network = var.google_compute_network_name
  subnetwork = var.google_compute_sub_network_name
}

# GKE クラスタのノードを定義
resource "google_container_node_pool" "primary_nodes" {
  name = "${var.app_name}-node-pool"
  location = var.region
  cluster = google_container_cluster.main.name
  node_count = 1

  node_config {
    preemptible = true
    machine_type = "e2-medium"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    # アクセススコープではすべてのサービスへの権限を付与し，サービスアカウント側で付与する権限を絞る
    service_account = google_service_account.gke_node_pool.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

