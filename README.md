HTML Importer for Movable Type
===========

* Author:: Yuichi Takeuchi <uzuki05@takeyu-web.com>
* Website:: http://takeyu-web.com/
* Copyright:: Copyright 2013 Yuichi Takeuchi
* License:: MIT License

既存の静的ウェブサイトからMovableType上への移行を支援する、HTMLインポーターです。

## 特徴

* 指定ディレクトリ以下の一括インポート
  * 対象/除外ディレクトリ指定可能
  * バックグラウンド処理対応
* 指定した1ファイルのみのインポート（予定）
* インポート元データソースとインポート先フィールド名によるルールを複数指定できる
  * データソースは CSSセレクタ 及び 正規表現 で抽出でき、柔軟な指定が可能
  * 例) インポート元「.wrap .content」 → インポート先「本文（text）」
  * インポート先にはカスタムフィールドも指定可能
* MovableType上の「フォルダ」の自動生成によるディレクトリ構造の維持
* 記事中に含まれる画像ファイルやリンク先のPDFなどのファイルをウェブページアイテムとして自動登録
* 無償＆無保証
  * サポートが必要な方は、他の有償プロダクトをお求め下さい
  * 何が起こっても開発者は一切責任を負いません

##WARNING!!

使い方を誤ると既存のウェブサイトを破壊する恐れもあるので注意して下さい。

操作ミスによる破壊を防ぐため、インポート元とインポート先（ウェブサイトパス）は別々にすることを強くお勧めします。


## 依存モジュール

  HTML::Selector::XPath 
  HTML::TreeBuilder::XPath

## バックグラウンド処理

MovableType標準の機構を利用して、時間のかかるインポートをバックグラウンドで実行することができます。

  # mt-config.cgi
  LaunchBackgroundTasks 1

##Contributing to HTML Importer

Fork, fix, then send me a pull request.

##Copyright
© 2013 Yuichi Takeuchi, released under the MIT license
