package HTMLImporter::L10N::ja;

use strict;
use warnings;
use base 'HTMLImporter::L10N::en_us';

use vars qw( %Lexicon );

%Lexicon = (
    '_PLUGIN_DESCRIPTION'   => '既存のHTMLファイルをMTのウェブページとして一括インポート、CMS化を支援します。',
    # config.yaml
    'Import from HTML'      => 'HTMLからインポート',
    "Import Source"         => "インポート元",
    # tmpl/start_import.tmpl
    'Import settings'   => 'インポート設定',
    'Document root(import from)'            => 'ドキュメントルート（インポート元）',
    'It is mapped to the web site root.'    => 'ウェブサイトルートにマッピングされます。',
    'Target type'       => '対象',
    'Directory'         => 'ディレクトリ',
    'File'              => 'ファイル',
    'Target sub directories'    => '対象サブディレクトリ',
    'Relative path for directory. Separated by a return.'    => '"インポート元ルートディレクトリ"以下にあるディレクトリのうち、対象とするものを相対パスで記入（改行区切り）',
    'Relative path for file. Separated by a return.'    => '"インポート元ルートディレクトリ"以下にあるファイルのうち、対象とするものを相対パスで記入（改行区切り）',
    'Relative path for file or directory. Separated by a return.'   => '"インポート元ルートディレクトリ"以下にあるディレクトリまたはファイルのうち、対象とするものを相対パスで記入（改行区切り）',
    'Exclude path (left-hand match)'    => '除外パス（前方一致）',
    'Target files'      => '対象ファイル',
    'Override(Not recommended)'    => '上書き（非推奨）',
    'Overwrite when an import target was present.'  => 'インポート先が存在するときに上書き（更新）します。',
    'Source type'       => 'データソース種別',
    'CSS Selector'      => 'CSSセレクタ',
    'Regular Expression'    => '正規表現',
    'Source'            => 'データソース',
    'Target field'      => 'インポート先フィールド',
    'Title(Override)'   => 'タイトル（上書き）',
    'Keywords(Override)'    => 'キーワード（上書き）',
    'Description(Override)' => '説明（上書き）',
    'Add rule'          => 'インポートルールを追加',
    'Start import'      => 'インポート開始',
    "'[_1]' has already been imported. Skipped."    => "'[_1]' はすでにインポートされています。スキップしました。",
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
    "Import Error: '[_1]' ([_2])"   => "インポートエラー： '[_1]'（[_2]）",
);