# Google Cloud の無料枠でインスタンスを利用する

## 概要
グローバルIP の付いた仮想マシンが 1台自由に使えるだけでも、何かとありがたいです。  
構築したシステムに正しくアクセス制限ができているかの外部からの確認に利用したり、さまざまなインストール検証を実施したり、個人としてできることが増えます。  
とはいえ、お金を払って維持するほどでも・・・というところに、大変ありがたい [Google Cloud の無料枠](https://cloud.google.com/free)があります。  
大手のパブリッククラウドサービスであっても、たいていは最初の 1ヶ月だけなど何かと無料枠には制限があり、使い続けることは難しいところ、なんと [e2-micro VMインスタンス](https://cloud.google.com/free/docs/gcp-free-tier/#compute)が、次の米国リージョンのいずれかで 1ヶ月無料で利用し続けることが可能です。
* オレゴン: us-west1
* アイオワ: us-central1
* サウスカロライナ: us-east1

これを利用しない手は無いということで、いつでも簡単に作成、削除できるように Terraform でコード化したので、ご紹介したいと思います。  
とはいえ、GCP についてあまり知識が無く、これで本当にベストプラクティスなんだろうか・・・というのはまったくわかっていませんので、アドバイス等ありましたら、ぜひコメントいただければ幸いです。

## 前提
インフラ構築の自動化には、[Terraform](https://www.terraform.io/)を利用します。  
私は [WSL2](https://docs.microsoft.com/ja-jp/windows/wsl/install) で Ubuntu20.04 の環境を利用していて、その中で Terraform を使っております。  
また個人的には [TerraformCloud](https://cloud.hashicorp.com/products/terraform) のアカウントを持っておくこともおすすめします。(無料版があります)  
こちらを利用することで、State(tfstate)ファイルを外部管理することができるようになり、コードも GitHub で管理すれば、特定の PC にしばられることなくいつでも最新の状態で作業が可能です。  
なお今回のサンプルでは .gitignore で除外していたりするのでわかりませんが、実際は以下のファイルがあって、これにより `backend "remote" {}` での管理が可能になっています。  
(workspace は `API-driven workflow` で作成し、Settings の `Execution Mode` は `local` にしておくのがよいかと思います)  

```shell:~/.terraformrc
credentials "app.terraform.io" {
  token = "***********************************************"
}
```

```shell:backend.hcl
workspaces { name = "XXXXXX" }
hostname     = "app.terraform.io"
organization = "XXXXXX"
```

また、gcloud CLI の利用も前提となりますので、ご利用の環境毎の[インストール、初期化方法](https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu?hl=ja)を確認の上、セットアップしてください。

最後に、当たり前ですが [Google Cloud Platoform](https://console.cloud.google.com/?hl=ja)を利用開始していることが前提ですので、その中でプロジェクトを作る、までは実施しておく必要があります。  
(クレジットカードの登録も必要だったと思いますが、本記事で紹介している作業のみを正しく実行した場合は、課金されることは無い・・・はずですのでご安心ください。初めて Google Cloud Platform を利用する場合は、$300相当の無料トライアルも利用できますのでより安心です。とはいえ、自己責任でお願いします)

## 基本的な流れ
1. 前提となる準備ができている環境で、今回ご用意したサンプルをクローンしてください。

	```
	git clone https://github.com/shztki/gcp_sample
	cd gcp_sample/
	```

1. 環境変数に以下をセットしてください。

	```Console:environment variable
	TF_VAR_gcp_user=~/.config/gcloud/legacy_credentials/アカウント名/adc.json
	TF_VAR_office_cidr=IPアドレス
	TF_VAR_gcp_project_id=**********
	```

	* 個人的には [direnv](https://github.com/direnv/direnv) おすすめです。 `~/.direnvrc` に環境変数を設定する関数を定義しておいて、各ディレクトリに `.envrc` ファイルを置いて実行することで、ディレクトリごとに必要な環境変数を切り替えられるようになって便利です。
	* クレデンシャルに関しては、Terraform用のサービスアカウントを作るなど、他にもやり方があるとは思うのですが、GCP の IAM関連がまったく理解できておらず、あきらめました。Googleアカウント(オーナー)をそのまま使う形にしているので、気になる場合は変更ください。また、もしロール(権限)が不足している場合は、IAM で「編集者」ロールを追加するだけでも、ひとまず動きます。なおコードの中で、Googleアカウントの @以前を SSHアカウント名にするように作っているため、もしクレデンシャルを変更する場合は SSH関連の処理も含めて変更してください。
	* 特定の環境からの SSH/ICMP のみを許可するように設定しているため、ご利用環境の IPアドレスを `TF_VAR_office_cidr` に設定ください。  
	(`curl inet-ip.info` 等のコマンドでも確認できます)
	* GCP でプロジェクトを作成し、その `プロジェクト ID` を `TF_VAR_gcp_project_id` に設定ください。

1. 準備ができたら以下を実行します。

	```Console:command
	terraform init -backend-config=backend.hcl
	terraform plan
	terraform apply
	```

	* `backend.hcl` を用意しない場合は、 `main.tf` の `backend "remote" {}` をコメントアウトして、コマンドも `terraform init` のみとし、ローカルでご利用ください。
	* `terraform` ではなく、 `make` でもできるように Makefile を用意してあります。構築時に `.ssh` フォルダが作成されてその中に SSH鍵が置かれますが、それとは別に `~/.ssh/` 配下にコピーしておきたかったので、その部分を自動化したいときは `make apply` するようにしています。

1. 問題無く実行できれば、us-east1 リージョンに e2-micro で Ubuntu20.04 の環境ができあがります。
	* 無料枠としては[リージョン](https://cloud.google.com/compute/docs/regions-zones?hl=ja)は 3つあるので、ゾーンも含め好きなものに変更可です。
	* OS を変更したい場合、　`gcloud compute images list` で確認して、 `PROJECT/FAMILY` の[組み合わせ等](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk#image)で変数に指定すればよいです。ただし、有償OS を誤って選択しないようにご注意ください。
	* ディスクは「30 GB-月の標準永続ディスク」が無料のようです。コード上は 10GB にしていますが、変更はご自由にどうぞ。
	* マルチゾーンに分散して作る時のために、あえて count を使いつつ、サブネットも 2個作ってあります(無料にするため、コード上はインスタンス作成は 1個としています)。
	* [SSH鍵](https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys?hl=ja)はあえて作らず、プロジェクト全体に登録して、 `gcloud ssh` で接続する、といった方法もあるようなのですが、何がベストプラクティスなのかわからず、あえて昔ながらのやり方にしています。なお、2年程度前にも同様のコードで作ったことがあるのですが、このときは metadata に登録した SSH鍵がそのままプロジェクト全体の SSH鍵としても登録される仕様になっていたようで、 `gcloud compute project-info describe` したときにすべて残っていて、 `block-project-ssh-keys ` を設定していないと、過去のユーザーアカウントがすべて新しいインスタンス内に作られてしまったりして、非常に気持ちの悪い思いをしました。私が GCP の勉強不足過ぎて知識が無いことが原因ではありますが、やはりにわかな対応をすると、思いがけない仕様に驚くことになるので、できたものがどういう状態かというのはきちんと確認して、何かおかしな点があれば調べる、といったことはきちんとやる必要があると思い知らされました。

## Tips1
いろんな情報を調べながら構築していたのですが、その中に「万が一課金されても気づけるように 1円の予算アラートを設定するとよい」というものがありました。  
なるほどと思い、メニューの「お支払い」にある「予算とアラート」でアラートを設定しました。  
(偶然なのかもしれませんが、「お支払い」を選択した後に関連するメニューが一切表示されなくなるときがありました。かなり困惑しましたが、そのときは直接検索してたどりつきました。コントロールパネルは UI が変わることもありますので、やはり GUI で覚えたり手順化することは好きになれませんし、不確実ですね。基本は全部 API で実行する方が無難だと思います)  
**適当な名前で目標金額を 1円としておいたところ、なんと数日後にアラートがあがりました。**  
これには非常にあせり、何かミスをしたのかと、いろいろ確認する羽目になりました。  
課金されていたのは本当に 1円なので、どうも転送量課金っぽいなと考えました。  
ただ、そういうことが無いようにファイアウォールには一切の公開ポリシーを設定していなかったので、とにかく謎です。  
暗黙の deny があるはずなので、自分の環境から許可した通信以外は一切できないはず・・・
ここでもいろんな事例を調べると、課金されるリージョンがあるからそこからの通信を deny しよう、みたいなものがでてきました。  
そもそも deny のはずなんだけどな・・・と思ったものの、とにかくこれ以上課金されても恐ろしいので、意味は無いとわかっていながらも、あえて設定したのが `firewll.tf` 末尾にある以下となっております。

```terraform: firewall.tf
resource "google_compute_firewall" "deny_example_all" {
  name    = format("%s-%s", "deny-all", module.label.id)
  network = module.vpc.network_name

  deny {
    protocol = "all"
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  priority      = 1001
}
```

その後、 **翌日には課金額が 0円に訂正されており、** どうやらなんらかの管理系の通信を誤カウントして課金してしまうものの、その後修正する、という動きをしているのでは・・・と推測しています。  
一度上がったアラートはその後は発報しないので、不安で 5円のアラートも設定しておいたのですが、それもまた数日後に 50% の 3円でアラートが上がりました。。。  
これもまた、翌日は 0円に戻っております。  
このため、結論として 1円や数円レベルのアラートでは、誤検知で発報されてとても嫌な思いをする、ということがわかりましたので、今は 10円のアラートを設定しています。  
これなら今のところ誤検知での発報はありません。  
(かつ、もちろん課金はされていません)  
ただ、信用できないというか怖いので、あえて入れた deny の設定は、残したままにしております。。。  

## Tips2
ちなみに、去年の途中頃までは f1-micro が無料でした。  
突然「f1-micro は無料じゃなくなる。課金されると困る場合は削除しろ。今後は e2-micro が無料になる」的な連絡が来て、あわてて削除したまま、しばらく作らずに放置していて、今回に至ったのでした。  
このことからも、ある日突然無料が終わったり、対象インスタンス種別が変わったり、といったことは今後もあると思います。  
英語のメールは読まないとか、気づかない、といった方は、こういった連絡を見逃して、うっかり課金されてしまう、といった事態にもなりかねませんので、この点は注意して利用すべきと思います。  

## Tips3
インスタンス内のネットワーク設定を見ると、なんとサブネットは /32 なのですね。  
AWSではふつうに VPC に設定するサブネットと同じ範囲になりますが、そうならないことにびっくりしました。  
この環境だけで学習する人がいたら、オンプレミスの環境などで設定するときに苦労することになるかもしれないですね。  

```Console:
$ ip a s
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1460 qdisc mq state UP group default qlen 1000
    link/ether 42:01:ac:10:00:02 brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    inet 172.16.0.2/32 scope global dynamic ens4
       valid_lft 75422sec preferred_lft 75422sec
    inet6 fe80::4001:acff:fe10:2/64 scope link
       valid_lft forever preferred_lft forever

$ ip r s
default via 172.16.0.1 dev ens4 proto dhcp src 172.16.0.2 metric 100
172.16.0.1 dev ens4 proto dhcp scope link src 172.16.0.2 metric 100
```

## 最後に
ということで、課金されたかのように見えるハプニングや、思いがけない仕様に驚くことなど、いろいろとありましたが、最終的に想定した通りの無料でずっと使えるインスタンスを作るコードが書けました。  
個人的にはかなり活用できそうなので、これからも使っていこうと思います。  
この情報が少しでも参考になれば幸いです。  
どうぞよい Google Cloud ライフを！  
