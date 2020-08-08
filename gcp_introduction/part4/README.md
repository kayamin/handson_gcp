
アクセススコープとサービスアカウントの関係

- アクセススコープにはすべてのサービスへのフル権限を付与しておき，サービスアカウントで許可するサービスを絞るのが良い
    - アクセススコープ x サービスアカウント の両方で許可されたサービスのみインスタンスは利用可能になる
    - アクセススコープはインスタンスごとに付与するもので，使い回しや，既存の権限の一覧性，管理性（無効化等）が低いので，今後は利用するべきではない
    - 権限管理周りはすべてサービスアカウントに寄せるのが良い   

- アクセススコープはレガシーな権限管理方法
    - インスタンス毎にどのGCPのAPIを利用できるかの許可設定を行う ( CloudStorage, CloudSQL etc)
- サービスアカウント
    - ロールベースの権限管理方法を実現するためのアカウント
    - サービスアカウントに対して，各サービスの利用を許可するIAMロールを紐付けられる
        - CloudStorage への 読み取り許可 etc
    - サービスアカウントをインスタンス等に紐付けることで，インスタンスの他のサービスへのアクセス権限を付与できる
    
- 参考
    - [サービス アカウント](https://cloud.google.com/compute/docs/access/service-accounts?hl=ja#service_account_permissions)
    - [レガシー アクセス スコープからの移行](https://cloud.google.com/kubernetes-engine/docs/how-to/access-scopes?hl=ja)
    
GCP における権限管理について

- 参考
    - [Cloud IAM 概要](https://cloud.google.com/iam/docs/overview?hl=ja)
    - [よくある質問](https://cloud.google.com/iam/docs/faq?hl=ja)
    - [ロールについて](https://cloud.google.com/iam/docs/understanding-roles?hl=ja)
        - 設定可能なロールはすべてここにまとまっている
    - [AWS プロフェッショナルのための Google Cloud: 管理](https://cloud.google.com/docs/compare/aws/management?hl=ja)
        - AWSと概念，用語が似ていて異なるので，それぞれちゃんと区別する必要がある
    - 複数のロールを一括して紐付ける方法
        - 配列で role 文字列を複数保持し，それぞれの要素ごとに resource を定義している
        - [Terraform で最小権限のサービスアカウントを使用する GKE クラスターを作る](https://blog.yukirii.dev/create-gke-with-least-privilege-sa-using-terraform/)
            - for_each を使う例
        - [TerraformでGCPのIAMをちょっとだけ上手に管理する](https://qiita.com/laqiiz/items/534a38d872b11603a9b8)
            - count を使う例
 
GCR とのイメージの push, pull は docker コマンドを用いる
 
- docker タグ `gcr.io/${project_id}/name:tag` をつける
    - `docker tag frontend:v1 gcr.io/leaarninggcp-ash/frontend:v1`
- `gcloud auth configure-docker` を実行することで docker コマンドが gcr.io とのやり取りをするための認証情報を設定する
- docker コマンドを用いてイメージを psh する
   - `docker push gcr.io/leaarninggcp-ash/backend:v1`
   - `docker push gcr.io/leaarninggcp-ash/frontend:v1`
    
GKE を kubectl コマンドで操作する

- gcloud コマンドの認証先を `gcloud init` で修正する
    - 最初 同じアカウントで GKEクラスターを作成したのとは別のプロジェクトに入っており，gke のクレデンシャルをコマンドで取得できなかった
- gke のクレデンシャルを gcloud コマンドで取得する
    - `gcloud container clusters get-credentials webserver-gke-cluster --region=asia-northeast1`
    - `~/.kube/config` に認証情報が保存される


なぜか kubectl apply -f をしても node が running にならない 
ー＞ ステータスが変わるのは node ではなく pod の方だった

pod は動いているがアプリケーションが応答しない？？ デバッグが必要

GCR にアップロードしたイメージを確認
```
❯ gcloud container images list  --repository=gcr.io/leaarninggcp-ash

NAME
gcr.io/leaarninggcp-ash/backend
gcr.io/leaarninggcp-ash/frontend


❯ gcloud container images list-tags gcr.io/leaarninggcp-ash/backend

DIGEST        TAGS  TIMESTAMP
d946ab5e89fb  v1    2020-08-03T22:00:58
```

クラスター起動初期状態
```
❯ kubectl get nodes
NAME                                                  STATUS   ROLES    AGE     VERSION
gke-webserver-gke-cl-webserver-node-p-3a25fb6f-mq1t   Ready    <none>   4m54s   v1.15.12-gke.2
gke-webserver-gke-cl-webserver-node-p-c825dde0-h0l5   Ready    <none>   4m58s   v1.15.12-gke.2
gke-webserver-gke-cl-webserver-node-p-ed1dfddb-gpxv   Ready    <none>   4m51s   v1.15.12-gke.2

❯ kubectl get pods
No resources found in default namespace.

❯ kubectl get services
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.35.240.1   <none>        443/TCP   9m25s
```

kubectl コマンドとymlファイルを用いて pods をデプロイ
```
❯ kubectl create -f config/backend-deployment.yaml
deployment.extensions/backend-node created

❯ kubectl get pods
NAME                            READY   STATUS              RESTARTS   AGE
backend-node-76d6568df8-5ldr7   0/1     ContainerCreating   0          6s
backend-node-76d6568df8-94pn9   0/1     ContainerCreating   0          6s
backend-node-76d6568df8-nhz5c   0/1     ContainerCreating   0          6s
```

kubectl コマンドとymlファイルを用いて service を作成
```
❯ kubectl create -f config/backend-service.yaml
service/backend-service created

❯ kubectl get services
NAME              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
backend-service   ClusterIP   10.35.254.78   <none>        8081/TCP   16s
kubernetes        ClusterIP   10.35.240.1    <none>        443/TCP    12m
```

kubectl コマンド介して yml ファイルを kubernetes コンテナに渡すことで pod のデプロイ等が可能
```
# クラスターとそのノードが起動していることを確認
kubectl get nodes

# 各ノードに docker イメージをデプロイする
kubectl create -f config/backend-deployment.yaml

kubectl get pods

# 複数のnode にまたがって 特定のpods にリクエストをロードバランスするためのくくり（サービス）を作成
kubectl create -f config/backend-sedrvice.yml

kubectl get services
```

pods 内に入ることが可能, localhost でアプリケーションが起動していることは確認できる 
```
kubectl exec -it frontend-node-7b69758ff5-bn28s /bin/bash

root@frontend-node-7b69758ff5-bn28s:/# curl localhost:8080/api/v1/games/1
{
  "board": null
}
```

Service が起動し，LB が紐付けられている，global IP が紐付いているが, curl 等でアクセスしても応答がない. GKEのClusterを配置しているVPCのFireWallRule で弾かれている？？
FirewallRule では ip は制限していないが，port を絞っているのでそれが原因か？？ 8080と8081 が遮断されている？？
Service では 80番 port を pod の 8080 portにマッピングしているから 80番にアクセスすればよかった. 
FireWallRule はこれはまた別で，そもそも deny 処理が効いていなさそう ?? \

- GKE 関連には 優先度1000 で 通信を許可する FireWall Rules が作成されている
    - 内部通信用だったら良いが
    - 0.0.0.0/0 で 80番 port の通信を許可する FireWall Rules も追加されている
    - これは何に対して適用されているのか？？ Cluster全体？？
        - 優先度を上げて明示的に拒否したことで 通信は遮断できたが 
 
```
❯ kubectl get services
NAME               TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
backend-service    ClusterIP      10.35.254.78    <none>           8081/TCP       86m
frontend-service   LoadBalancer   10.35.252.120   35.189.136.207   80:32488/TCP   77m
kubernetes         ClusterIP      10.35.240.1     <none>           443/TCP        98m

```




## Project 内で AppEngine が起動していないと DataStore が動かない!?

- [Google Cloud Datastore requires app engine?](https://stackoverflow.com/questions/45223410/google-cloud-datastore-requires-app-engine)
- DataStore にアクセスし DataStore モードを選択　ー＞　開始 としたアプリケーションからアクセスできるようになった
    - アプリケーションからは project id を指定してクライアントを作成しただけでアクセスできている (驚き)
 


kubernetes について

- [独学Kubernetes　コンテナ開発の基本を最速で理解する](https://qiita.com/Brutus/items/d19af6b9c55de93663f6)

    
# tips

- [GKE で k8s クラスタの node に ssh する](https://qiita.com/sonots/items/6e2a57af945cf0daedd4)
- SlideShare
    - [GKE & Spanner 勉強会  GKE 入門](https://www.slideshare.net/GoogleCloudPlatformJP/gke-spanner-gke)
    - [株式会社コロプラ『GKE と Cloud Spanner が躍動するドラゴンクエストウォーク』第 9 回 Google Cloud INSIDE Game & Apps](https://www.slideshare.net/GoogleCloudPlatformJP/gke-cloud-spanner-9-google-cloud-inside-game-apps)
    - [Google Container Engine (GKE) & Kubernetes のアーキテクチャ解説](https://www.slideshare.net/HammoudiSamir/google-container-engine-gke-kubernetes)
- [Terraformを用いてVPCネットワークにGKE限定公開クラスタを構成する](https://qiita.com/y-uemurax/items/4376e27ccc0b2dcc85f0)

    