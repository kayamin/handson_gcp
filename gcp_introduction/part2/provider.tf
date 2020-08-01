provider "google" {
  credentials = "${file("../leaarninggcp-ash-f1fac35cf5ff.json")}"
  project = "leaarninggcp-ash"
  region = "asia-northeast1"
}