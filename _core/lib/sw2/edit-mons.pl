############# フォーム・モンスター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';
use Encode;

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::lib_palette_sub;
### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_mons;

### データ読み込み ###################################################################################
my ($data, $mode, $file, $message) = pcDataGet($::in{'mode'});
our %pc = %{ $data };

my $mode_make = ($mode =~ /^(blanksheet|copy|convert)$/) ? 1 : 0;

### 出力準備 #########################################################################################
if($message){
  my $name = tag_unescape($pc{'characterName'} || $pc{'monsterName'} || '無題');
  $message =~ s/<!NAME>/$name/;
}
### 製作者名 --------------------------------------------------
if($mode_make && !$::make_error){
  $pc{'author'} = (getplayername($LOGIN_ID))[0];
}
### 初期設定 --------------------------------------------------
$pc{'protect'} = $pc{'protect'} ? $pc{'protect'} : 'password';
$pc{'group'} = $pc{'group'} ? $pc{'group'} : $set::group_default;

$pc{'statusNum'}  = $pc{'statusNum'} ? $pc{'statusNum'} : 1;
$pc{'lootsNum'}   = $pc{'lootsNum'} ? $pc{'lootsNum'} : 2;
if($mode eq 'blanksheet'){
  $pc{'paletteUseBuff'} = 1;
}

### 改行処理 --------------------------------------------------
$pc{'skills'}      =~ s/&lt;br&gt;/\n/g;
$pc{'description'} =~ s/&lt;br&gt;/\n/g;
$pc{'chatPalette'} =~ s/&lt;br&gt;/\n/g;


### フォーム表示 #####################################################################################
print <<"HTML";
Content-type: text/html\n
<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="UTF-8">
  <title>@{[$mode eq 'edit'?"編集：$pc{'monsterName'}":'新規作成']} - $set::title</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/base.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/sheet.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/monster.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/sw2/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <script src="${main::core_dir}/lib/sw2/edit-mons.js?${main::ver}" defer></script>
  <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.3.1/css/all.css" integrity="sha384-mzrmE5qonljUremFsqc01SB46JvROS7bZs3IO2EmfFsd15uHvIt+Y8vEf7N7fWAU" crossorigin="anonymous">
  <style>
    #image {
      background-image: url("${set::char_dir}${file}/image.$pc{'image'}");
    }
    #image > * {
      background: rgba(255,255,255,0.8);
    }
  </style>
</head>
<body>
  <script src="${main::core_dir}/skin/_common/js/common.js?${main::ver}"></script>
  <header>
    <h1>$set::title</h1>
  </header>

  <main>
    <article>
      <aside class="message">$message</aside>
      <form id="monster" name="sheet" method="post" action="./" enctype="multipart/form-data">
      <input type="hidden" name="ver" value="${main::ver}">
      <input type="hidden" name="type" value="m">
HTML
if($mode_make){
  print '<input type="hidden" name="_token" value="'.token_make().'">'."\n";
}
print <<"HTML";
      <input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">
      <div id="area-name">
        <div id="monster-name">
          <div>名称@{[ input 'monsterName','text','','required' ]}</div>
          <div>名前@{[ input 'characterName','text','','placeholder="※名前を持つ魔物のみ"' ]}</div>
        </div>
        <div>
        <p id="update-time"></p>
        <p id="author-name">製作者@{[input('author')]}</p>
        </div>
HTML
if($mode eq 'edit'){
print <<"HTML";
        <input type="button" value="複製" onclick="window.open('./?mode=copy&type=m&id=$::in{'id'}@{[ $::in{'backup'}?"&backup=$::in{'backup'}":'' ]}');">
HTML
}
print <<"HTML";
        <input type="submit" value="保存">
        <ul id="header-menu">
          <li onclick="sectionSelect('common');">キャラクターデータ</li>
          <li onclick="sectionSelect('palette');">チャットパレット</li>
        </ul>
      </div>
HTML
if($set::user_reqd){
  print <<"HTML";
    <input type="hidden" name="protect" value="account">
    <input type="hidden" name="protectOld" value="$pc{'protect'}">
    <input type="hidden" name="pass" value="$::in{'pass'}">
HTML
}
else {
  if($set::registerkey && $mode_make){
    print '登録キー：<input type="text" name="registerkey" required>'."\n";
  }
  print <<"HTML";
      <details class="box" id="edit-protect" @{[$mode eq 'edit' ? '':'open']}>
      <summary>編集保護設定</summary>
      <p id="edit-protect-view"><input type="hidden" name="protectOld" value="$pc{'protect'}">
HTML
  if($LOGIN_ID){
    print '<input type="radio" name="protect" value="account"'.($pc{'protect'} eq 'account'?' checked':'').'> アカウントに紐付ける（ログイン中のみ編集可能になります）<br>';
  }
    print '<input type="radio" name="protect" value="password"'.($pc{'protect'} eq 'password'?' checked':'').'> パスワードで保護 ';
  if ($mode eq 'edit' && $pc{'protect'} eq 'password') {
    print '<input type="hidden" name="pass" value="'.$::in{'pass'}.'"><br>';
  } else {
    print '<input type="password" name="pass"><br>';
  }
  print <<"HTML";
<input type="radio" name="protect" value="none"@{[ $pc{'protect'} eq 'none'?' checked':'' ]}> 保護しない（誰でも編集できるようになります）
      </p>
      </details>
HTML
}
  print <<"HTML";
      <section id="section-common">
      <dl class="box" id="hide-options">
        <dt>閲覧可否設定</dt>
        <dd id="forbidden-checkbox">
          <select name="forbidden">
            <option value="">内容を全て開示
            <option value="battle" @{[ $pc{'forbidden'} eq 'battle' ? 'selected' : '' ]}>データ・数値のみ秘匿
            <option value="all"    @{[ $pc{'forbidden'} eq 'all'    ? 'selected' : '' ]}>内容を全て秘匿
          </select>
        </dd>
        <dd id="hide-checkbox">
          <select name="hide">
            <option value="">一覧に表示
            <option value="1" @{[ $pc{'hide'} ? 'selected' : '' ]}>一覧には非表示
          </select>
        </dd>
        <dd>
          ※一覧に非表示でもタグ検索結果・マイリストには表示されます
        </dd>
      </dl>
      <div class="box" id="group">
        <dl>
          <dt>分類</dt><dd><select name="taxa">
HTML
foreach (@data::taxa){
  print '<option '.($pc{'taxa'} eq @$_[0] ? ' selected': '').'>'.@$_[0].'</option>';
}
print <<"HTML";
          </select></dd>
          <dt>タグ</dt><dd>@{[ input 'tags' ]}</dd>
        </dl>
      </div>
      <div class="box status">
        <dl><dt>レベル</dt><dd>@{[ input 'lv','number','','min="0"' ]}</dd></dl>
        <dl><dt>知能</dt><dd>@{[ input 'intellect','','','list="data-intellect"' ]}</dd></dl>
        <dl><dt>知覚</dt><dd>@{[ input 'perception','','','list="data-perception"' ]}</dd></dl>
        <dl><dt>反応</dt><dd>@{[ input 'disposition','','','list="data-disposition"' ]}</dd></dl>
        <dl><dt>穢れ</dt><dd>@{[ input 'sin','number','','min="0"' ]}</dd></dl>
        <dl><dt>言語</dt><dd>@{[ input 'language' ]}</dd></dl>
        <dl><dt>生息地</dt><dd>@{[ input 'habitat' ]}</dd></dl>
        <dl><dt>知名度／弱点値</dt><dd>@{[ input 'reputation' ]}／@{[ input 'reputation+' ]}</dd></dl>
        <dl><dt>弱点</dt><dd>@{[ input 'weakness','','','list="data-weakness"' ]}</dd></dl>
        <dl><dt>先制値</dt><dd>@{[ input 'initiative' ]}</dd></dl>
        <dl><dt>移動速度</dt><dd>@{[ input 'mobility' ]}</dd></dl>
        <dl><dt>生命抵抗力</dt><dd>@{[ input 'vitResist',($pc{'statusTextInput'} ? 'text':'number'),'calcVit' ]} (@{[ input 'vitResistFix',$pc{'statusTextInput'} ? 'hidden':'number','calcVitF' ]})</dd></dl>
        <dl><dt>精神抵抗力</dt><dd>@{[ input 'mndResist',($pc{'statusTextInput'} ? 'text':'number'),'calcMnd' ]} (@{[ input 'mndResistFix',$pc{'statusTextInput'} ? 'hidden':'number','calcMndF' ]})</dd></dl>
      </div>
      <p>@{[ input "statusTextInput",'checkbox','statusTextInputToggle']}命中・回避・抵抗に数値以外を入力</p>
      <div class="box">
      <table id="status-table" class="status">
        <thead>
          <tr>
            <th></th>
            <th>攻撃方法</th>
            <th>命中力</th>
            <th>打撃点</th>
            <th>回避力</th>
            <th>防護点</th>
            <th>ＨＰ</th>
            <th>ＭＰ</th>
          </tr>
        </thead>
        <tbody>
HTML
foreach my $num (1 .. $pc{'statusNum'}){
$pc{"status${num}Damage"} = '2d6+' if $pc{"status${num}Damage"} eq '' && $mode eq 'blanksheet';
print <<"HTML";
        <tr id="status-row${num}">
          <td class="handle"></td>
          <td>@{[ input "status${num}Style" ]}</td>
          <td>@{[ input "status${num}Accuracy",($pc{'statusTextInput'} ? 'text':'number'),"calcAcc($num)" ]}<br>(@{[ input "status${num}AccuracyFix",($pc{'statusTextInput'} ? 'hidden':'number'),"calcAccF($num)" ]})</td>
          <td>@{[ input "status${num}Damage" ]}</td>
          <td>@{[ input "status${num}Evasion",($pc{'statusTextInput'} ? 'text':'number'),"calcEva($num)" ]}<br>(@{[ input "status${num}EvasionFix",($pc{'statusTextInput'} ? 'hidden':'number'),"calcEvaF($num)" ]})</td>
          <td>@{[ input "status${num}Defense" ]}</td>
          <td>@{[ input "status${num}Hp" ]}</td>
          <td>@{[ input "status${num}Mp" ]}</td>
        </tr>
HTML
}
print <<"HTML";
        </tobdy>
      </table>
      <div class="add-del-button"><a onclick="addStatus()">▼</a><a onclick="delStatus()">▲</a></div>
      @{[input('statusNum','hidden')]}
      </div>
      <div class="box parts">
        <dl><dt>部位数</dt><dd>@{[ input 'partsNum','number','','min="0"' ]} (@{[ input 'parts' ]}) </dd></dl>
        <dl><dt>コア部位</dt><dd>@{[ input 'coreParts' ]}</dd></dl>
      </div>
      <div class="box">
        <h2>特殊能力</h2>
        <textarea name="skills">$pc{'skills'}</textarea>
        <div class="annotate">
          ※特殊能力の分類マークなどを記述すると自動的に見出し化します。<br>
           2.0での分類マークでも構いません。また、入力簡易化の為に入力しやすい代替文字での入力も可能です。<br>
           以下に見出しとして変換される記号を一覧にしています。<br>
          ●：部位見出し：<code>●</code><br>
          <i class="s-icon passive"></i>：常時型　　：<code>○</code> <code>◯</code> <code>〇</code><br>
HTML
if($::SW2_0){
print <<"HTML";
          <i class="s-icon major0"   ></i>：主動作型　：<code>＞</code> <code>▶</code> <code>〆</code><br>
          <i class="s-icon minor0"   ></i>：補助動作型：<code>≫</code> <code>&gt;&gt;</code> <code>☆</code><br>
          <i class="s-icon condition"></i>：条件型　　：<code>▽</code><br>
          <i class="s-icon selection"></i>：条件選択型：<code>▼</code><br>
HTML
} else {
print <<"HTML";
          <i class="s-icon setup"  ></i>：戦闘準備型：<code>△</code><br>
          <i class="s-icon major"  ></i>：主動作型　：<code>＞</code> <code>▶</code> <code>〆</code><br>
          <i class="s-icon minor"  ></i>：補助動作型：<code>≫</code> <code>&gt;&gt;</code> <code>☆</code><br>
          <i class="s-icon active" ></i>：宣言型　　：<code>🗨</code> <code>□</code> <code>☑</code><br>
HTML
}
print <<"HTML";
        </div>
      </div>
      <div class="box loots">
        <h2>戦利品</h2>
        <div id="loots-list">
          <ul id="loots-num">
HTML
foreach my $num (1 .. $pc{'lootsNum'}){ print "<li id='loots-num${num}'><span class='handle'></span>".input("loots${num}Num").'</li>'; }
print <<"HTML";
          </ul>
          <ul id="loots-item">
HTML
foreach my $num (1 .. $pc{'lootsNum'}){ print "<li id='loots-item${num}'><span class='handle'></span>".input("loots${num}Item").'</li>'; }
print <<"HTML";
        </ul>
      </div>
      <div class="add-del-button"><a onclick="addLoots()">▼</a><a onclick="delLoots()">▲</a></div>
      @{[input('lootsNum','hidden')]}
      </div>
      <div class="box">
        <h2>解説</h2>
        <textarea name="description">$pc{'description'}</textarea>
      </div>
      </section>
      
      <section id="section-palette" style="display:none;">
      <div class="box">
        <h2>チャットパレット</h2>
        <p>
          手動パレットの配置:<select name="paletteInsertType" style="width: auto;">
            <option value="exchange" @{[ $pc{'paletteInsertType'} eq 'exchange'?'selected':'' ]}>プリセットと入れ替える</option>
            <option value="begin"    @{[ $pc{'paletteInsertType'} eq 'begin'   ?'selected':'' ]}>プリセットの手前に挿入</option>
            <option value="end"      @{[ $pc{'paletteInsertType'} eq 'end'     ?'selected':'' ]}>プリセットの直後に挿入</option>
          </select>
        </p>
        <textarea name="chatPalette" style="height:20em" placeholder="例）&#13;&#10;2d6+{冒険者}+{器用}&#13;&#10;&#13;&#10;※入力がない場合、プリセットが自動的に反映されます。">$pc{'chatPalette'}</textarea>
        
        <div class="palette-column">
        <h2>デフォルト変数 （自動的に末尾に出力されます）</h2>
        <textarea id="paletteDefaultProperties" readonly style="height:20em">
HTML
  say $_ foreach(paletteProperties('m'));
print <<"HTML";
</textarea>
          <label>@{[ input 'chatPalettePropertiesAll', 'checkbox']} 全ての変数を出力する</label><br>
          （デフォルトだと、未使用の変数は出力されません）
        </div>
        <div class="palette-column">
        <h2>プリセット （コピーペースト用）</h2>
        <textarea id="palettePreset" readonly style="height:20em"></textarea>
        <p>
          <label>@{[ input 'paletteUseVar', 'checkbox','palettePresetChange']}デフォルト変数を使う</label>
          ／
          <label>@{[ input 'paletteUseBuff', 'checkbox','palettePresetChange']}バフデバフ用変数を使う</label>
          <br>
          使用ダイスbot: <select name="paletteTool" onchange="palettePresetChange();" style="width:auto;">
          <option value="">ゆとチャadv.
          <option value="bcdice" @{[ $pc{'paletteTool'} eq 'bcdice' ? 'selected' : '']}>BCDice
          </select>
        </p>
        </div>
      </div>
      </section>
    
      @{[ input 'birthTime','hidden' ]}
      @{[ input 'id','hidden' ]}
    </form>
HTML
if($mode eq 'edit'){
print <<"HTML";
    <form name="del" method="post" action="./" id="deleteform">
      <p style="font-size: 80%;">
      <input type="hidden" name="mode" value="delete">
      <input type="hidden" name="type" value="m">
      <input type="hidden" name="id" value="$::in{'id'}">
      <input type="hidden" name="pass" value="$::in{'pass'}">
      <input type="checkbox" name="check1" value="1" required>
      <input type="checkbox" name="check2" value="1" required>
      <input type="checkbox" name="check3" value="1" required>
      <input type="submit" value="シート削除"><br>
      ※チェックを全て入れてください
      </p>
    </form>
HTML
}
print <<"HTML";
    </article>
  </main>
  <footer>
    『ソード・ワールド2.5』は、「グループSNE」及び「KADOKAWA」の著作物です。<br>
    　ゆとシートⅡ for SW2.5 ver.${main::ver} - ゆとらいず工房
  </footer>
  <datalist id="data-intellect">
  <option value="なし">
  <option value="動物並み">
  <option value="低い">
  <option value="人間並み">
  <option value="高い">
  <option value="命令を聞く">
  </datalist>
  <datalist id="data-perception">
  <option value="五感">
  <option value="五感（暗視）">
  <option value="五感（）">
  <option value="魔法">
  <option value="機械">
  </datalist>
  <datalist id="data-disposition">
  <option value="友好的">
  <option value="中立">
  <option value="敵対的">
  <option value="腹具合による">
  <option value="命令による">
  </datalist>
  <datalist id="data-weakness">
  <option value="命中力+1">
  <option value="物理ダメージ+2点">
  <option value="魔法ダメージ+2点">
  <option value="属性ダメージ+3点">
  <option value="回復効果ダメージ+3点">
  <option value="なし">
  </datalist>
  <script>
  let palettePresetText = {
    'ytc'    : { 'full': `@{[ palettePreset('','m')       ]}`, 'simple': `@{[ palettePresetSimple('','m')       ]}` } ,
    'bcdice' : { 'full': `@{[ palettePreset('bcdice','m') ]}`, 'simple': `@{[ palettePresetSimple('bcdice','m') ]}` } ,
  };
  </script>
</body>

</html>
HTML

1;