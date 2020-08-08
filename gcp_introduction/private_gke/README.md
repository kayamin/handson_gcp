# Private なネットワークの構築と GKE のプライベート化について

- Private な VPCネットワークを構築する
    - FireWallRule で通信を制御する
        - INGRESS は 暗黙のFireWallRule ですべて拒否になっているのでそのままでOK (ルールの優先度は最低なので注意)
        - EGRESS は 明示的にすべてを拒否する必要がある (暗黙のFireWallRule ではすべて許可になっている)
            - 内部IPに向かうEGRESSは許可するように FireWallRule を追加する
    - default-internet-gateway への ルートを削除する
        - VPCを作成するとネクストホップがネクストホップをdefault-internet-gatewayとする， 0.0.0.0/0 を引き受けるデフォルトルートが作成される
        - インターネットへ通じる通信経路も一応削除しておいたほうが良い
    - Google API と内部通信をするため設定をする
        - サブネットで Private Google Access を有効にする
        - Google API への内部通信を可能にするために，199.36.153.4/30 を引き受けるルートを作成する (ネクストホップは default-internet-gateway)
            - default-internet-gateway　をしているが，Private Google Access を有効にしているので通信はGoogle APIへのプライベート内部パスを辿るようにルーティング される
            - 0.0.0.0/0 を引き受けて default-internet-gateway へ渡すルートを削除しているのでこの設定が必要，削除しないのであればこのルートは不要
    - *.googleapi.com に対する通信が上記で作成したルートに名前解決されるように DNSゾーンを作成する
        - サブネット内で googleapis.com (何かしらのGCPサービス）に対して通信が行われた際に，内部通信経路を通るようにする必要がある
            - 何もしないとパブリックIPに名前解決される ->  VPCで外部への通信を絞っているので
            - このURLは GCPネットワーク内でアクセス可能な特定の範囲199.36.153.4/30に解決されるようになっている(上記ルートで設定した範囲と同じ)
        - 手順
            - Cloud DNS で googleapis.com のプライベートゾーンを作成
            - *.googleapis.com を restricted.googleapis.com に読み替える CNAME レコードを作成したゾーンに追加
            - restricted.googleapis.com を 199.36.153.4/30　の適当は ip に解決する Aレコードを，作成したゾーンに追加
                - 例: "199.36.153.4" "199.36.153.5" "199.36.153.6" "199.36.153.7

- GKE をプライベート化
    - クラスターを作成する際に複数のオプションを指定し private にする
        - 前提
            - private にすることを指定しないと，クラスターマスター，各ノードにpublic ip が付与される
            - 同時に，任意のipからマスター・ノードへアクセス可能とするFireWall Rules も作成される．．．（しなくてもよいのでは．．）
                - 暗黙の FireWall Rules で遮断されていると思っていると，優先度1000 で通信を許可する FireWall Rule が作成されて通信ができるようになってしまうので注意
            - 承認済みネットワーク の設定を用いて，FireWall Rule とは別に GKE 側で，アクセス可能な ip を制限することが可能
                - デフォルトは無効になっており，承認済みネットワーク でのフィルタリングは効いていない
                - 仮にパブリックなエンドポイントが有効になったとしても、マスタ承認済みネットワークの設定で遮断可能
        - 指定するパラメータ
            - `enable-private-nodes`
                - GKEのノードに private ip のみを付与するように指定
            - `eneble-private-endopoint`
                - GKEのクラスタマスターに private ip のみを付与するように指定
            - `enable-master-authorized-networks`
                - クラスターが紐付けられたサブネットワーク以外からのアクセスも，master-authorized-networks で指定されていれば可能とする
            - `master-authorized-networks` 
                - マスターへアクセス可能とするネットワークを指定する
                - 何も指定しなければクラスターのノード等からしかマスターへはアクセスできなくなる
            - `master-ipv4-cidr`
                - マスタのCIDRを指定，`--enable-private-nodes`を指定する際には必須
                - グローバルip がマスターに付与されない -> private ip 内で付与する必要があるが，ネットワーク内で被ってはいけない -> 被らないように作成時にレンジを指定する必要がある？
            - `enable-ip-alias`
                - クラスタをVPCネイティブに切り替える
    - gcr.io への通信が内部通信となるように VPCネットワークにプライベートゾーンを追加する
        - [GKE 限定公開クラスタの Container Registry の設定](https://cloud.google.com/vpc-service-controls/docs/set-up-gke?hl=ja)
        - > [限定公開クラスタでは、コンテナ ランタイムはコンテナ イメージを Container Registry から pull できますが、インターネット上の他のコンテナ イメージ レジストリからイメージを pull することはできません。これは、限定公開クラスタ内のノードには外部 IP アドレスがなく、デフォルトでは Google ネットワーク外のサービスと通信できないため](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#public_master)
        - Private Google Access が有効になってるサブネット かつ， gcr.io への通信が 199.36.153.4/30 の範囲に名前解決される必要がある
        - ※ 199.36.153.4/30 の範囲 が default-internet-gateway　につながるように VPCサブネットのルートが構成されていなくてはいけない
             
         

- [インターネット接続なしの完全にプライベートなGKEクラスター](https://qiita.com/baby-degu/items/c7cdeef0c91b059a41df)
    - [Completely Private GKE Clusters with No Internet Connectivity](https://medium.com/google-cloud/completely-private-gke-clusters-with-no-internet-connectivity-945fffae1ccd)
    - private なネットワーク，クラスタ作成方法が詳細に記されている

- [How to use a Private Cluster in Kubernetes Engine](https://github.com/GoogleCloudPlatform/gke-private-cluster-demo#private-clusters)
    - Terraform での構成例
    - README.md の説明が詳しく書かれておりわかりやすい

- [それなりにセキュアなGKEクラスタを構築する](https://qiita.com/t0m0ya/items/e400a0afc9a8a2bdc58d)

- [VPC ネイティブ クラスタを作成する](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips?hl=ja)
    - Pod への ip 割当方式が VPCネイティブ，ルートベースの２通りある
    - プライベートクラスタを作成する場合は VPCネイティブにしなくてはいけない（新しいバージョンではこっちがデフォルト)
        - > [限定公開クラスタは、エイリアス IP 範囲が有効な VPC ネイティブ クラスタである必要があります。新しいクラスタでは、VPC ネイティブがデフォルトで有効になります。](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters?hl=ja#req_res_lim)
    
- [Terraformを用いてVPCネットワークにGKE限定公開クラスタを構成する](https://qiita.com/y-uemurax/items/4376e27ccc0b2dcc85f0)
    - 2つの VPCネットワーク をつなげるには VPCピアリングが必要
        - [Multiple networks in same project? [closed]](https://stackoverflow.com/questions/54718966/multiple-networks-in-same-project#:~:text=The%20instances%20within%20the%20VPC,each%20other%20across%20the%20globe.&text=If%20two%20VPC%20networks%20use,feasible%20between%20both%20VPC%20networks.)
            - VPCピアリングをするネットワーク同士は IPレンジは被っていてはいけない
        - VPCネットワーク は一つの閉じた物理的なネットワークと考えれば良い. 同じネットワーク内でのみ private ip で接続可能
        - 異なるVPCネットワークと private ip を用いて通信したい場合は VPCピアリングが必要
    
  

[GCP の細かすぎて伝わらないハイブリッドネットワーキング](https://medium.com/google-cloud-jp/gcp-%E3%81%AE%E7%B4%B0%E3%81%8B%E3%81%99%E3%81%8E%E3%81%A6%E4%BC%9D%E3%82%8F%E3%82%89%E3%81%AA%E3%81%84%E3%83%8F%E3%82%A4%E3%83%96%E3%83%AA%E3%83%83%E3%83%89%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AD%E3%83%B3%E3%82%B0-14ed12ebe84d)    
> なお、GCP では基本的にはあまり多くの VPC は作成せず、Shared VPC を活用することで少数の中央集権的な VPCでシステムを構成する方法をお勧めしています。なので「VPC がたくさんできちゃったから VPN でつなご！」という場合、なんでたくさんできちゃったかを考えてみましょう。

> そのため、オンプレミス環境から Cloud SQL や、限定公開の GKE のマスターに直接アクセスしたい場合は VPC ピアリング カスタム経路 import export (と Cloud Router のカスタム経路広告)が必須になるのです。

[AWS プロフェッショナルのための Google Cloud: ネットワーキング](https://cloud.google.com/docs/compare/aws/networking)


# VPCネットワークの構成３パターン

基本は事前に共有VPCを作成し，管理することを検討するのが良い

- VPCネットワークを個別に作成 x VPCピアリング
    - 通信したいVPCネットワーク間すべての間でVPCピアリングを設定する必要がある (フルメッシュ型)
- VPCネットワークを個別に作成 x Cloud VPN
    - CloudVPN を介してハブ型のネットワークを構成可能
    - 複数のVPCネットワーク間を簡単につなぐことができる
- 共有VPC をホストプロジェクトで作成し管理 x 個々のproject で利用
    - 複数のプロジェクトで用いるネットワークを一元管理できる
    - 共有VPC内のネットワークは private ip で通信できる
 
 
- [GCPに限定公開なサブネットを作成する](https://tech-tech.nddhq.co.jp/2020/06/12/post-274/)
    - 限定公開なサブネット = そのサブネット内にリソースには グローバル IP が割り当てられなくなる ?
    - 限定公開のGoogleアクセス(Private Google access) を有効にすれば作成できる ?
        - Set whether VMs in this subnet can access Google services without assigning external IP addresses
        - この説明文を見る限りは CloudStorage 等に private ip でアクセスできるようになるだけで，内部のリソース自体はパプリックip を持ててしまうのでは？？
   
- [GKEで限定公開クラスタを作成する](https://tech-tech.nddhq.co.jp/2020/06/16/post-277/)
    - > このクラスタは以下の記事で紹介した限定公開なサブネットに作成してもグローバルIPアドレスを持ってしまいます
        - 限定公開とリソースの private 化はあまり関係ないと思われる
 

外部との通信に必要な条件

1.グローバルIPを持っている
- グローバルIPが存在しないと戻りトラフィックが戻ってこれない (通信が成立しない)
- GKE の private 化　オプションを指定した場合，サブネットで外部通信を許可しても GKEのノードに グローバルIPが存在しないため，gcr.io で名前解決されるグローバルIP と通信ができない
    - Private Google Access を用いると プライベートIP しかなくても GCP 関連のサービスとは通信ができる 

2.外部への通信が許可されている
- グローバルIPを有していても，ネットワークのFireWallRules で遮断されていると通信はできない
        

[サービスのプライベート アクセス オプション](https://cloud.google.com/vpc/docs/private-access-options)