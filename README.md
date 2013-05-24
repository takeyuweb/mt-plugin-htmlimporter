HTML Importer for Movable Type
===========

* Author:: Yuichi Takeuchi <uzuki05@takeyu-web.com>
* Website:: http://takeyu-web.com/
* Copyright:: Copyright 2013 Yuichi Takeuchi
* License:: MIT License

既存の静的ウェブサイトからMovableType上への移行を支援する、インポーターです。

## 特徴

* 指定ディレクトリ以下の一括インポート
* 指定した1ファイルのみのインポート（予定）
* インポート元CSSセレクタとインポート先フィールド名によるルールを複数指定できる
  * 例) インポート元「.wrap .content」 → インポート先「本文（text）」
  * インポート先にはカスタムフィールドも指定可能
* MovableType上の「フォルダ」の自動生成によるディレクトリ構造の維持
* 記事中に含まれる画像ファイルやリンク先のPDFなどのファイルをウェブページアイテムとして自動登録
* 無償＆無保証
  * サポートが必要な方は、他の有償プロダクトをお求め下さい
  * 何が起こっても開発者は一切責任を負いません

##WARNING!!

本プラグインは開発中バージョンです。

一応の動作はしますが、不足している機能があるほか、大きな仕様変更の可能性があります。

使い方を誤ると既存のウェブサイトを破壊する恐れもあるので注意して下さい。


## 依存モジュール

  HTML::Selector::XPath 
  HTML::TreeBuilder::XPath


##Contributing to HTML Importer

Fork, fix, then send me a pull request.

##Copyright
© 2013 Yuichi Takeuchi, released under the MIT license
