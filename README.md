HTML Importer for Movable Type
===========

* Author:: Yuichi Takeuchi <uzuki05@takeyu-web.com>
* Website:: http://takeyu-web.com/
* Copyright:: Copyright 2013 Yuichi Takeuchi
* License:: MIT License

既存の静的ウェブサイトからMovableType上への移行を支援する、HTMLインポーターです。

本プラグインを用いて、1000ページ程度のDreamweaverで作成されたサイトをMovableType上にインポートしており、それなりに使えるはずです。

## 機能

* インポート元の指定
  * 指定したディレクトリ以下の一括インポート
    * 対象ディレクトリを複数指定可能
    * 除外パスを複数指定可能（前方一致）
  * 指定したファイル一覧の一括インポート
* 柔軟なインポートルール
  * インポート元データソースとインポート先フィールド名によるルールを複数指定できる
    例) インポート元「.wrap .content」 → インポート先「本文（text）」
    * データソース
      * CSSセレクタ または 正規表現 で抽出可能
    * インポート先
      * ウェブページの各フィールド（タイトル、本文、続き、キーワード、概要）
      * カスタムフィールド
* 「フォルダ」構造の維持
  * MovableType上の「フォルダ」の自動生成
* アイテムインポート
  * 記事中に含まれる画像ファイルやリンク先のPDFなどのファイルをウェブページアイテムとして自動登録
* インポートスクリプトを用いた自動インポート
* コールバックによる拡張
* 無償＆無保証
  * サポートが必要な方は、他の有償プロダクトをお求め下さい
  * 何が起こっても開発者は一切責任を負いません

##画面サンプル

![画面サンプル](https://raw.github.com/uzuki05/mt-plugin-htmlimporter/master/main.png)


## 依存モジュール

* HTML::Selector::XPath 
* HTML::TreeBuilder::XPath

## バックグラウンド処理

MovableType標準の機構を利用して、時間のかかるインポートをバックグラウンドで実行することができます。

    #mt-config.cgi
    LaunchBackgroundTasks 1

ただし、PSGI動作時の時は、バックグラウンド処理は無効になります。（MTのバックグラウンド処理機構が無効化されるため）

## スクリプトを用いた自動インポート

`plugins/HTMLImporter/sample/tools/sync-from-html`にプラグインの機能を利用して、大量のページを取り込むための作業支援スクリプトのサンプルを含めています。

## プラグインによる拡張

コールバックを利用してインポート処理を拡張できます。

サンプルとして`plugins/HTMLImporter/sample/plugins/SyncCheck`に、カスタムフィールドの値をチェックして上書きインポートを行うかどうか判断するプラグインを含めています。

## コールバック

### cms\_pre_htmlimport.page

インポートされたウェブページが保存される前に呼ばれます。
偽を返すことで保存せずスキップします。

    # カスタムフィールド page_skip_htmlimport が真のときインポートしないサンプル
    # 例えば、インポート済みのウェブページについて、「上書き」が選択されても上書きしたくないときなど
    sub _cb_cms_pre_htmlimport_page {
        my ( $cb, $app, $obj, $original ) = @_;
        
        my $field = 'field.page_skip_htmlimport';
        if ( $obj->$field ) {
            return $app->error( 'Skipped.' );
        } else {
            return 1;
        }
    }

### cms\_post_htmlimport.page

インポートされたウェブページや記事アイテムなどが保存された後に呼ばれます。

    sub _cb_cms_post_htmlimport_page {
        my ( $cb, $app, $obj, $original ) = @_;
        
        # インポートされたウェブページオブジェクトについての処理
        
        1;
    }

##Contributing to HTML Importer

Fork, fix, then send me a pull request.

##Copyright
© 2013 Yuichi Takeuchi, released under the MIT license
