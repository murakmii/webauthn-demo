# WebAuthn Demo

## これはなに?

コミックマーケット95で頒布予定の同人誌「Getting started with WebAuthn」で部分的に参照している、  
WebAuthnによる認証のサンプル実装の完全版です。実際に手元で動作させることができます。

## Setup

### Docker

[Dockerfile](https://github.com/murakmii/webauthn-demo/blob/master/Dockerfile)の内容に従ってビルドしたコンテナイメージを、
Docker Hubに[murakmii/webauthn-demo](https://cloud.docker.com/u/murakmii/repository/docker/murakmii/webauthn-demo)として登録済みです。  
`docker run`により最終的にWebサーバーが立ち上がり、所定のURLでアクセスすることができるようになります。

```sh
docker pull murakmii/webauthn-demo:v1.0
docker run -d -p 9292:80 murakmii/webauthn-demo:v1.0

open "http://localhost:9292"
```

### bundle install & rackup

本リポジトリの実装ではRubyを用いています。  
そのため `bundle install` を使用した、一般的なRubyプロジェクトと同様の方法でセットアップすることも難しくありません。  
`bundle exec rackup`によりデモ用のWebサーバーを起動することができます。  
データベース等の周辺環境のセットアップは不要です。

```sh
git clone git@github.com:murakmii/webauthn-demo
cd webauthn-demo

bundle install --path=vendor/bundle --without development test
bundle exec rackup -E production

open "http://localhost:9292"
```

### 環境変数の設定

本リポジトリの実装は、デフォルトでは `http://localhost:9292` というURLでアクセスされることを前提とした実装となっています。  
別のURL(例えば異なるポート番号)でアクセスしたい場合、環境変数 `WEBAUTHN_ORIGIN` に適切なURLを設定しWebサーバーを起動してください。

```sh
# docker
docker run -d -p 8080:80 -e WEBAUTHN_ORIGIN="http://localhost:8080" murakmii/webauthn-demo:v1.0

# bundler
WEBAUTHN_ORIGIN="http://localhost:8080" bundle exec rackup -E production -p 8080
```

## デモの利用

デモ用のWebサーバーが起動したら、最低限のサインアップとログインを試すことが出来ます。  
YubiKeyのようなAuthenticatorを所持していることが前提となるので、留意してください。

URL(ほとんどの場合、 `http://localhost:9292` )にアクセスすると、以下のようなページが表示されます。

<img src="https://github.com/murakmii/webauthn-demo/blob/master/README/index.png?raw=true" width="400" />

「サインアップ」ボタンからサインアップページへ、「ログイン」ボタンからログインページへ遷移することができます。

### サインアップ

適当なユーザーIDを決め、フォームに入力し「サインアップ」ボタンを押下することでWebAuthnのRegistrationが開始されます。  
(画像はChromeのバージョン 70.0.3538.110 でサインアップを行なった場合の画像)

<img src="https://github.com/murakmii/webauthn-demo/blob/master/README/signup.png?raw=true" width="400" />

Registrationを完了させるための操作はAuthenticatorによって様々です。  
例えばYubiKey 4であればタッチ部分が点滅するため、それをタッチすることでRegistrationを完了させることができます。

Registrationが完了したら、そのユーザーIDを使ってログインを行うことができます。  
(Registration完了後は、ログインページへの遷移を促すUIが表示されます)

### ログイン

サインアップに使用したユーザーIDを用いてログインを行うことができます。  
ユーザーIDをフォームに入力し、「ログイン」ボタンを押下することでWebAuthnのAuthenticationが開始されます。

<img src="https://github.com/murakmii/webauthn-demo/blob/master/README/login.png?raw=true" width="400" />

その後はRegistrationと同様、手元のブラウザーとAuthenticatorに合わせた操作でAuthenticationを完了させてください。  
完了後はログイン済みとなります。  
(ログインしたからと言って、何か特別なページがあるわけでもないのですが...)

## 諸注意

本リポジトリの実装はデモ用であるため、データの永続化やパフォーマンス面で実用的でない実装を行なっています。  
血迷っても実用することはオススメしません。

## その他

 * 実装のために[jQuery](https://github.com/jquery/jquery)と[base64-js](https://github.com/beatgammit/base64-js)を使用しています。
