## private IP を持つ CloudSQLインスタンスを作成するには

- 理解しておく前提
    - CloudSQL のインスタンスはユーザーが定義したVPC内に作成することは出来ない
    - お客様の VPC ネットワークと、Cloud SQL インスタンスが存在する Google サービスの VPC ネットワークとの間の VPC ピアリング接続 をする必要がある
    - VPC ネットワーク感の Private IP を用いたトラフィックは Googleのネットワーク内部で完結する
- 手順
    1. 利用するVPC を作成
    2. GCP内グローバルに利用可能な Private IP アドレスレンジを作成する (上記VPCのIPレンジとは無関係に作成して良い，どうせなら被らないほうが良い)
    3. 作成した Private IP アドレスレンジを 作成したVPC に割り当てる
    4. CloudSQL を作成する際に，上記VPCを指定するとVPCに 3. で割り当てられた Private IP アドレスレンジを用いて，別のGoogle管理VPCに CloudSQLインスタンスが作成される
    　- 先にPrivate IP レンジを確保しておくのは VPC内での他のリソースと，CloudSQLに設定した Private IP が被らないようにするため    

- 注意
    - private IP のみを付与し public IP は付与しない場合, 同じVPC内のリソースからしかアクセスできないので注意
        - Cloud Shell から `gcloud sql connect` で接続しようとしてもCloudShell用インスタンスが立てられるVPCが異なるので CloudSQLには接続できない
   

- 参考
    - [Terraform × GCP 入門](https://qiita.com/donko_/items/6289bb31fecfce2cda79)          
    - [Cloud SQL で private IP を付与する際に気をつけたいこと](https://tech.zeals.co.jp/entry/2020/03/05/140627?utm_source=feed)
    - [プライベート IP](https://cloud.google.com/sql/docs/mysql/private-ip?hl=ja)
    - [プライベート IP の構成](https://cloud.google.com/sql/docs/mysql/configure-private-ip?hl=ja)
    - [google_sql_database_instance](https://www.terraform.io/docs/providers/google/r/sql_database_instance.html#master_instance_name)
        - terraform での構築例 
    - [Google Cloud SQL - Catch bad logins](https://stackoverflow.com/questions/60055828/google-cloud-sql-catch-bad-logins)
        - This is caused because you are trying to connect to the Cloud SQL instance using the gcloud command when you have configured a private IP. You will not be able to connect to your Cloud SQL instance with MySQL workbench either since they are not in the same network
       
## google_compute_address と google_compute_global_address の違い

- 用意できる静的IPには regional, global の２種類が存在する
- regional
    - 同じ region, zone 内のリソースから その IP を用いてアクセスが可能
- global
    - global forwarding rules でのみ利用可能で global load balancing で用いられる
    - region, zone 単位で定義するリソースには紐付けられない
- CloudSQL で使う private ip は global で作成するのだが，一方で VPC との紐付ける関係上，同じVPC(=同じリージョン)からしかその private IP を使ってアクセスできない ようになっていると考えられる
    
https://cloud.google.com/compute/docs/ip-addresses#reservedaddress
> Static external IP addresses can be either a regional or a global resource. A regional static IP address allows resources of that region or resources of zones within that region to use the IP address. In this case, VM instances and regional forwarding rules can use a regional static IP address.

> Global static external IP addresses are available only to global forwarding rules, used for global load balancing. You can't assign a global IP address to a regional or zonal resource.


## Compute Engine の startup_script の実行はうまく行かないこともあるのでおかしいときは実行履歴を確認する

https://cloud.google.com/compute/docs/startupscript?hl=ja

```
sudo journalctl -u google-startup-scripts.service
```