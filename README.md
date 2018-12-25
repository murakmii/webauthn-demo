# WebAuthn Demo

## これはなに?

コミックマーケット95で頒布予定の同人誌「Getting started with WebAuthn」で部分的に参照していた、  
WebAuthnによる認証のサンプル実装の完全版です。実際に手元で動作させることができます。

## Setup

### Docker

TODO: 書く

### bundle install & rackup

`bundle install`を使用した、一般的なRubyプロジェクトと同様の方法でセットアップすることも難しくありません。  
データベース等の周辺環境のセットアップは不要です。

```sh
git clone git@github.com:murakmii/webauthn-demo
cd webauthn-demo

bundle install --path=vendor/bundle
bundle exec rackup

open "http://localhost:9292"
```

## 諸注意

本リポジトリの実装はデモ用であるため、データの永続化やパフォーマンス面で実用的でない実装を行なっています。  
血迷っても実用することはオススメしません。

## その他

 * 実装のために[jQuery](https://github.com/jquery/jquery)と[base64-js](https://github.com/beatgammit/base64-js)を使用しています。
