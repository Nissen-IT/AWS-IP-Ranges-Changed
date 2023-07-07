# AWS 東京リージョン (ap-northeast-1) の IPアドレス範囲の変更を特定
この PowerShell スクリプトは AWS の IPアドレス範囲を取得して、前回取得しておいたIPアドレス範囲との比較を行って、AWS の IPアドレス範囲の変更を特定するものです。<br>
スケジューラー等で定期的に実行することで、IPアドレス範囲の変更の検知を自動化することができます。
1. AWS Tools for Windows PowerShell のコマンドで AWS の IPアドレス範囲の変更を検知し、変更があった場合に IPアドレス範囲を取得します。
2. 前回取得しておいた IPアドレス範囲のファイルとの比較を行い、変更点を抽出します。
3. 変更があった場合のみメールにて通知します。
4. 今回取得した IPアドレス範囲を、次回の比較の為にファイルに保管します。
## システム要件
1. AWS Tools for Windows PowerShell がインストールされていること。
## 初回実行までの準備
ルートにある PublicationDate_Old.txt には、以前取得した IPアドレス範囲が公開された日付が入っています。<br>
初回実行にあたっては、比較の元にしたい IPアドレス範囲のバージョン日付を記載してください。<br>
現在の IPアドレス範囲のバージョン日付を取得したい場合は、次のコマンドで取得できます。<br>

`Get-AWSPublicIpAddressRange -OutputPublicationDate | Out-File PublicationDate_Old.txt`

Data フォルダの中にある AwsIPs_Reference.txt ば、IPアドレス範囲を比較する際の「以前の」IPアドレス範囲として利用されます。<br>
初回実行にあたっては、比較の元にしたい IPアドレス範囲に置き換えてください。<br>
現在の IPアドレス範囲を取得したい場合は、次のコマンドで取得できます。<br>

`Get-AWSPublicIpAddressRange -Region ap-northeast-1 | Select IpPrefix,IpAddressFormat,Region | Where-Object IpAddressFormat -match "Ipv4" | Out-File AwsIPs_Reference.txt`
# Azure Automation 実行版
Azure Automation では、AWS Tools for Windows PowerShell が使えない為、AWS から IP アドレス範囲が記載された JSON を取得し、以前の JSON と比較することで IP アドレス範囲の変更を検知します。<br>
なお、Azure Automation 実行版は、既定で ap-northeast-1（東京リージョン）だけでなく、GLOBAL の IP アドレスの変更も併せて検出します。GLOBAL を取得する必要が無い場合には、スクリプトを修正してください。
## システム要件
* Azure Automation アカウント
* Azure Blob Storage
* SendGrid アカウント
## 初回実行までの準備
* Azure Blob Storage に任意のコンテナを作成します。
* 作成した Blob Storage コンテナのルートに AWS の IPアドレス範囲が気指された JSON を "Reference.json" として保存してください。<br>
最新の JSON は以下の URL から取得できます。<br>
https://ip-ranges.amazonaws.com/ip-ranges.json
* 実行時のパラメーターを設定してください。<br>
スクリプト内に直接記述する設定と、実行時のパラメータで渡す設定があります。<br>
実行時のパラメータで渡す設定については、Azure Automation のジョブ設定時に併せて設定してください。
    * 設定をスクリプト内に直接記載するもの（設定箇所の表示あり）<br>
        * SendGrid API キー
        * メールの送信元アドレス
        * メールの件名
    * 設定を実行時のパラメーターで渡すもの
        * Azure Storage アカウント名
        * Blob コンテナ名
        * Azure Storage の API キー
        * メールの宛先アドレス
