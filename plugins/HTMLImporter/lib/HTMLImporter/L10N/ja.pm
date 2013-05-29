package HTMLImporter::L10N::ja;

use strict;
use warnings;
use base 'HTMLImporter::L10N::en_us';

use vars qw( %Lexicon );

%Lexicon = (
    '_PLUGIN_DESCRIPTION'   => '既存のHTMLファイルをMTのウェブページとして一括インポート、CMS化を支援します。',
    # config.yaml
    'Import from Web Site'  => 'ウェブサイトからインポート',
    'Import from HTML'      => 'HTMLからインポート',
    # tmpl/start_import.tmpl
    'Import settings'   => 'インポート設定',
    'Import from'       => 'インポート元ルートディレクトリ',
    'It is mapped to the web site root.'    => 'ウェブサイトルートにマッピングされます。',
    'Target sub directories'    => '対象サブディレクトリ',
    'Separated by a return.'    => '"インポート元ルートディレクトリ"以下にあるディレクトリのうち、対象とするものを改行区切りで記入。「.」の場合すべて。',
    'Exclude sub directories'    => '除外サブディレクトリ',
    'Override(Not recommended)'    => '上書き（非推奨）',
    'Overwrite when an import target was present.'  => 'インポート先が存在するときに上書き（更新）します。',
    'Source type'       => 'データソース種別',
    'CSS Selector'      => 'CSSセレクタ',
    'Source'            => 'データソース',
    'Target field'      => 'インポート先フィールド',
    'Title(Override)'   => 'タイトル（上書き）',
    'Keywords(Override)'    => 'キーワード（上書き）',
    'Description(Override)' => '説明（上書き）',
    'Add rule'          => 'インポートルールを追加',
    'Start import'      => 'インポート開始',
    "'[_1]' has already been imported."    => "'[_1]' はすでにインポートされています。",
    # tmpl/import.tmpl
    'Start Importing'       => 'インポート開始',
    'Imported'              => 'インポート完了',
    'Target directories'    => '対象ディレクトリ',
    'Exclude directories'   => '除外ディレクトリ',
    # lib/HTMLImporter/Plugin.pm
    'Asset file is not found. (href: [_1] / absolute_path: [_2])'   => 'アセットの実ファイルが見つかりません。（href: [_1] / 絶対パス: [_2]）',
    'Start importing from HTML.'        => 'HTMLインポートを開始しました。',
    'Finish importing from HTML.'       => 'HTMLインポートを完了しました。',
    "imported: '[_1]'"      => "インポートしました： '[_1]'",
    "Import Error: '[_1]' ([_2])"   => "インポートしました： '[_1]'（[_2]）",
);