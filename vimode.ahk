; vim: set sw=4 sts=4 ts=4 tw=0 noet ai fdm=marker cms=;%s:
IniRead, vExclusion , vimode.ini ,ahk_class,exclusion
IniRead, vDraw_tooltip , vimode.ini ,seconds,draw_tooltip
IniRead, vMouse_move , vimode.ini ,points,mouse_move

if (vExclusion = "ERROR" ){
  msgbox, iniファイルに除外ウィンドウが設定されていない。
  exitapp
}

if (vDraw_tooltip= "ERROR" ){
  vDraw_tooltip=250
}

if (vMouse_move= "ERROR" ){
  vMouse_move=10
}

#HotkeyInterval 2000
#MaxHotkeysPerInterval 100

#WinActivateForce
#Include %A_ScriptDir%
#Include IME.ahk


;TODO:
;a～zの名前付きレジスタ等。クリップボード内容をファイルに保存して実現可能と思われ。
;
;   読み込み
;   FileRead, Clipboard, *c %FILENAME%
;
;   書き込みor新規作成
;   FileDelete, %FILENAME%
;   FileAppend, %ClipboardAll%, %FILENAME%
;
;   "" : 無名レジスタ＝クリップボード
;       いつでも更新
;
;   "0～"9 : 番号付きレジスタ ※1～9は履歴
;       yy,ddと、行単位visual時に更新
;
;   "- : 小削除用レジスタ
;       yy,ddと、行単位visual時に更新
;
;   "a～"z "A～"Z : 名前付きレジスタ
;       指定時のみ。大文字は追記
;
;   ひとまずここまで対応したい。その他のレジスタは保留


;####################################################################
;変数と初期値
;####################################################################
;{{{
; ※ #if に使用できるのは英字のみ？ blankは判定不能

;vimode
; 0 (VIモード無効)
; 1 normal
; 2 insert
; 3 Number
; 4 Command(operator)
; 5 Command line
; 6 Search          ;未使用
; 7 Replace
; 8 mouse(original)
vimode=0

;除外APへ行ったときに、モードを退避する
vimode_shelter=0

;visualmode
; 0:通常（選択モードではない）
; 1:文字選択モード
; 2:行選択モード
; 3:矩形選択モード(対応アプリのみ)
visualmode=0

;カットバッファ内が行単位の場合に、1
yankmode = 0

;command(operator)
; [vimode=4]のときに使用
; 0  -
; 1  d   delete
; 2  y   yank
; 3  g   gg(ファイル先頭)
; 4  c   change
; 5  r   replace(1文字) ※rは通常モードコマンドだが、Rはモード自体が違う
; 6  z   zh,zl
; 7  "   レジスタ指定
; (以下実装方法未定※何エディタを想定？メモ帳,eclipse,sakura,hidemaru等？)
;   m   bookmark
;   '   bookmark
;   f   検索
;   F   前方検索
;   q   macro
;   @   macro
command=0

n_count=
commandline=
ex_commandline=

;"/" or  "?"
searchmode=
searchword=
;}}}

; セミコロンエンター
; Teams や Discord での Shift+Enter 改行も、Teams や Slack の Ctrl+Enter 送信にも対応させる。
`;::Send, {Enter}
+`;::Send, +{Enter}
^`;::Send, ^{Enter}

; Ctrl+; が打ちづらいので、無変換を修飾キーとして通常のセミコロンを送る。
; Blind なので Shift, Ctrl 同時押しも可能。普通に + も入力できる。
sc07b & `;::Send, {Blind}`;

; ctrl-[, ctrl-h, ctrl-j は指が慣れすぎてて、もう戻すことができない。
^h::Send, {Backspace}
^j::Send, {Enter}
^[::Send, {Esc}

; Ctrl+h でバックスペースは慣れているので問題なし
sc07b & h::Send, {Blind}{BackSpace}
; Ctrl+[ のエスケープは標準マッピングだが遠い。
; ので eScape なので比較的押しやすいホームポジション近くのキーにマッピングしたい
sc07b & s::
sc07b & [::
  Send, {Blind}{ESC}
  return

sc07b & m::Send, {AppsKey}
sc07b & x::Send, ^+x ;; Teams 用。Ctrl+Shift+X より打ちやすい。

;; 設定のリロード
sc07b & r::Reload


;; 無変換 + N, J で input モードに
sc07b & l::
    IME_SET(0)
    return
sc07b & j::
    IME_SET(1)
    ; 音声入力で日本語を入力を行うことになったので、skkのモード切り替えのキーストロークが不要になった。
    ; Send, ^j
    return

;;####################################################################
;;タスク制御等　(起動したら通常モードでも有効。除外無し)
;;####################################################################
;{{{

$^+h::
  Send,^#{Left}     ;デスクトップ左
  sleep,50
  WinGet,hoge,ID,A
  IfEqual hoge
    Send,!{ESC}
  return
$^+l::
  Send,^#{Right}        ;デスクトップ右
  sleep,50
  WinGet,hoge,ID,A
  IfEqual hoge
    Send,!{ESC}
  return
  ;アニメーション停止手順
  ;コントロールパネル、システムとセキュリティ、システム、システムの詳細設定
  ;「システムのプロパティ」ダイアログの「詳細設定」タブ、パフォーマンスパネルの「設定」ボタン
  ;「ウインドウを最大化や最小化するときにアニメーションで表示する」を外す。

sc07b & t::
$^+j::
  Send,#t           ;タスクバー
  return

;^+k::AltTabAndMenu     ;alt+tab    ※3キーは無理？

sc07b & k::
$^+k::
  Send,#{Tab}       ;デスクトップ切り替え
  return


;Alt+Tab タスク切り替え中
#IfWinActive ahk_class MultitaskingViewFrame
  !h::!Left
  !j::!Down
  !k::!Up
  !l::!Right
  !d::!Delete
#IfWinActive


;Win+Tabのデスクトップ切り替え
#IfWinActive ahk_class XamlExplorerHostIslandWindow ahk_exe Explorer.EXE

  h::Left
  j::Down
  k::Up
  l::Right
  `;::Enter
  w::                                       ;右のデスクトップへ(ジャンプリスト時は何もしない)
    ifWinActive ,タスク ビュー            ;ahkファイルは、UTF-8のBOM付きにしておかないと、上手く判定されないので注意。
    {
      BlockInput,on
      Send,+{Tab}
      Send,{Right}
      Send,{Space}
      Send,{Tab}
      BlockInput,off
    }
    return
  b::                                       ;左のデスクトップへ(ジャンプリスト時は何もしない)
    ifWinActive ,タスク ビュー
    {
      BlockInput,on
      Send,+{Tab}
      Send,{Left}
      Send,{Space}
      Send,{Tab}
      BlockInput,off
    }
    return

#IfWinActive

;タスクバーで右クリックしたジャンプリスト（最近使ったもの）
#IfWinActive ahk_class Windows.UI.Core.CoreWindow ahk_exe ShellExperienceHost.exe
  j::Down
  k::Up
  `;::Enter
  ESC::
  ^h::
    BlockInput,on
    Send,{Esc}
    Send,#{t}
    BlockInput,off
    return
#IfWinActive

;Win+T タスクバー
#IfWinActive ahk_class Shell_TrayWnd
  h::Left
  j::return             ;なにもしない（Ctrl+Shift+Jで入ってくるので反応してしまう）
  k::Up                 ;プレビュー
  l::Right
  `;::Enter
  w::
    BlockInput,on
    Send,{Right}        ;右のアプリのプレビュー
    Send,{Up}
    BlockInput,off
    return
  b::                       ;左のアプリのプレビュー
    BlockInput,on
    Send,{Left}
    Send,{Up}
    BlockInput,off
    return
  :::
    Send,{AppsKey}      ;ジャンプリスト表示
    return
#IfWinActive

;Win+T タスクバーのプレビュー
#IfWinActive ahk_class TaskListThumbnailWnd
  h::Left
  l::Right
  j::Down                   ;タスクバーへ戻る
  w::
    BlockInput,on
    Send,{Down}         ;右のアプリのプレビュー
    Send,{Right}
    Send,{Up}
    BlockInput,off
    return
  b::                       ;左のアプリのプレビュー
    BlockInput,on
    Send,{Down}
    Send,{Left}
    Send,{Up}
    BlockInput,off
    return
  Enter:: Send,{Enter}  ;選択
  x::
    BlockInput,on
    Send,{AppsKey}
    sleep,200           ;右クリックメニューが出るまで時間がかかるのか、cが空振る事がある。
    Send,c
    BlockInput,off
    return
#IfWinActive

;}}}

;####################################################################
;vimodeの有効/無効
;####################################################################
;{{{
#IfWinNotActive ahk_class Vim

; 無変換単体で vimode の On/Off
; モードを切り替えるときは、必ずimeをオフにする。
sc07b::
  IME_SET(0)
  if ( vimode=0 or vimode="" )
  {
    vimode=1
    gosub,mode_end
    settimer,draw_tooltip ,%vDraw_tooltip%
  }
  else
  {
    vimode=0
    settimer,draw_tooltip,off
    tooltip,
    BlockInput,off
    ;終了時にリロードしておいて、再開時は変更内容が反映された状態に。
    ;動作が不安定になった場合などにも。
    ; Reload
  }
  return

+^[::
  if ( vimode=0 or vimode="" )
  {
    vimode=1
    gosub,mode_end
    settimer,draw_tooltip ,%vDraw_tooltip%
  }
  return
#IfWinNotActive

+^]::
+^\::                       ;ULE4JIS時に、無効にできないので暫定対処
  vimode=0
  settimer,draw_tooltip,off
  tooltip,
  BlockInput,off
  Reload                    ;終了時にリロードしておいて、再開時は変更内容が反映された状態に。
              ;動作が不安定になった場合などにも。
  return
;}}}

;####################################################################
;状態描画（タイマー起動）
;####################################################################
;{{{
draw_tooltip:
  ;アクティブウィンドウの左下隅
  WinGetActiveStats, title,myWide,myHigh,myX,myY
  ;msgbox,"%title%" is %myWide% wide`,%myHigh% tall` and positioned at %myX%`,%myY%.
  myWide=%myX%
  myHigh+=%myY%
  myWide+=10
  myHigh-=30

  CoordMode ,tooltip,Screen     ;絶対座標

  IfWinActive ahk_class XLMAIN  ;Excel
  {
    myWide+=25
    myHigh-=50

    ControlGetFocus, temp
    if temp=EXCEL61             ;セル内
    {
      ControlGetPos,cx,cy,cw,ch,EXCEL61
      ;msgbox,%cx% . %cy% . %cw% . %ch%

      myWide=%cx%
      myHigh=%cy%
      myHigh+=%ch%
      CoordMode ,tooltip,Relative       ;相対座標
    }
  }

  ifWinActive ahk_class PPTFrameClass       ;パワポ
  {
    ;myWide+=25
    myHigh-=25
  }

  ;除外APがアクティブだった場合は無効に変える。
  SetTitleMatchMode,RegEx
  ignoreAp=0
  IfWinActive ahk_class (%vExclusion%)
    ignoreAp=1

  IfWinActive ahk_class XLMAIN  ;Excelの
  {
    ControlGetFocus, temp
    if temp=EXCEL=1             ;シート名変更時は無効
      ignoreAp=1
  }


  if vimode<>8                              ;マウスモード以外
  {
    if ( ignoreAp=1 )                       ;除外対象
    {
      if vimode_shelter=0                   ;退避してない（除外APをアクティブにした直後）
      {
        vimode_shelter=%vimode%         ;現在のモードを退避
        ;msgbox,%vimode_shelter%
      }
      vimode=0                          ;一次的に無効にする。
    }
    else {                                  ;除外APではないのにタイマー起動している。（戻ってきた）
      if vimode=0                           ;無効になっている。
      {
        ;msgbox,%vimode_shelter%
        vimode=%vimode_shelter%         ;除外APをアクティブにした直後の時点のモードを戻す。
        vimode_shelter=0                ;避難所を空に
                        ;TODO:  現状、なぜか挿入モードだったのが通常モードになって戻る事がある。
                        ;       （このままの方がいいのかも）
      }
    }
  }
  else                                      ;マウスモードの場合は、ウィンドウ切り替え中のみ無効に
  {
    ifWinActive ahk_class MultitaskingViewFrame
    {
      if vimode_shelter=0                   ;退避してない（除外APをアクティブにした直後）
      {
        vimode_shelter=%vimode%         ;現在のモードを退避
        ;msgbox,%vimode_shelter%
      }
      vimode=0                          ;一次的に無効にする。
    }
  }

  SetTitleMatchMode,1
  ;除外AP監視 ここまで


  if vimode=0                               ;vimodeが無効な場合は、非表示にする。
    tooltip,
  else if vimode=1                      ;ノーマルモード
  {
    if visualmode=0
      tooltip,vimode, %myWide%,%myHigh%
    else if visualmode=1
      tooltip,vimode[-visual-], %myWide%,%myHigh%
    else if visualmode=2
      tooltip,vimode[-visual line-], %myWide%,%myHigh%
    else if visualmode=3
      tooltip,vimode[-visual box-], %myWide%,%myHigh%
  }
  else if vimode=2                      ;インサートモード
  {
    tooltip,vimode[-insert-], %myWide%,%myHigh%

    IfWinActive ahk_class XLMAIN        ;Excelの
    {
      ControlGetFocus, temp
      if temp!=EXCEL61              ;セル外の場合は、
      {
        gosub,mode_end              ;通常モードに戻る。
      }
    }
  }
  else if vimode=3                      ;ノーマルモードの数値入力中
    tooltip,vimode[%n_count%], %myWide%,%myHigh%
  else if vimode=31                     ;数指定のreplace用
    tooltip,vimode[%n_count%%commandline%], %myWide%,%myHigh%
  else if vimode=4                      ;オペレータ待機モード等。2ストローク以上の機能待ち。
  {
    tooltip,vimode[%commandline%%n_count%], %myWide%,%myHigh%
    IfEqual commandline                 ;オペレータが無い場合（何故？）
    {
      gosub,mode_end
    }
  }
  else if vimode=5                      ;コマンドラインモード（:の後）
  {
    tooltip,vimode[:], %myWide%,%myHigh%
    IfWinNotExist , vimode: ahk_class #32770    ;モード残り（inputboxが出ていないのに5のまま）対応
    {
      gosub,mode_end
    }
  }
  else if vimode=6                      ;検索(/の後) ※Ctrl-Fに置き換えているので未使用
    tooltip,vimode[%searchmode%%searchword%], %myWide%,%myHigh%
  else if vimode=7                      ;置換モード
    tooltip,vimode[-replace-], %myWide%,%myHigh%
  else if vimode=8                      ;moouseモード
    tooltip,vimode[-mouse-], %myWide%,%myHigh%
  else
  {
    ;msgbox,error(vimode="%vimode%")
    vimode=0
  }


  CoordMode ,tooltip,Relative
  return

;}}}

;####################################################################
;通常モード
;####################################################################
;{{{
#If ( vimode=1 )
  ESC::
  ^[::
    gosub,input_escape
    return

  Enter::
    gosub,input_enter
    return

  ^j::Send,{Enter}

  ^m::
    vimode=8                            ;mouseモード
    return

  Space::
    if visualmode=0
      send,{right}
    else
      send,+{right}

    return

  +Space::
    if visualmode=0
      send,^{right}
    else
      send,+^{right}

    return

  ;################################
  ;カーソル移動系
  ;################################
  h::gosub,move_h

  ^h::
    IfWinActive ahk_class XLMAIN    ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61          ;セル外
      {
        send,^h                 ;置換
        return
      }
    }
    gosub,move_h                    ;ノーマルモードのCtrl-hは左移動するのみ
    return

  j::gosub,move_j
  k::gosub,move_k
  l::gosub,move_l
  w::gosub,move_w
  e::gosub,move_e
  b::gosub,move_b
  0::gosub,move_0
  ^::gosub,move_^
  $::gosub,move_$
  +::gosub,move_+
  -::gosub,move_-
  ^f::gosub,move_^f
  ^b::gosub,move_^b
  ^y::gosub,move_^y
  ^e::gosub,move_^e

  !h::Send,!{Left}
  !l::Send,!{Right}

  +g::                                  ; G : ファイル末尾へ
    if visualmode=0                     ;選択中でない場合は、末尾へジャンプ
      Send,^{End}
    else                                ;選択中の場合は、末尾まで選択
      Send,+^{End}
    return

  ;センテンス移動は難しいのでエクセル等で便利なCtrl上下を設定しておく
  (::Send,^{UP}
  )::Send,^{Down}

  ;################################
  ;行結合
  ;################################
  +j::
    BlockInput,on
    Send,{End}
    Send,{End}
    Send,{Delete}
    BlockInput,off
    return

  ;################################
  ;undo/redo
  ;################################
  u::
    Send,^z
    return

  ^r::
    Send,^y
    return

  ;################################
  ;挿入モード移行
  ;################################
  ;カーソル位置に挿入
  i::gosub,insert_start

  ;行頭に挿入
  +i::
    if visualmode<>0
      gosub,mode_end
    Send,{Home}
    gosub,insert_start
    return

  ;カーソル位置の右に追加
  a::
    if visualmode!=0            ;visualモードの場合は無効
      return

    IfWinActive ahk_class XLMAIN    ;Excel
    {
      ControlGetFocus, temp
      if temp=EXCEL61               ;セル内の場合だけ右移動。（セル外は右移動しない）
      {
        Send,{Right}
      }
      gosub,insert_start
      return
    }
    Send,{Right}
    gosub,insert_start
    return

  ;行末尾に追加
  +a::
    if visualmode<>0
      return
    Send,{end}
    gosub,insert_start
    return

  ;1行追加
  o::
    if visualmode<>0
      return            ;todo:選択範囲の先頭末尾トグル(無理ゲ)

    IfWinActive ahk_class XLMAIN    ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61          ;セル外
      {
        BlockInput,on
        IME_SET(0)
        send,{down}             ;次の行
        Send,+{Space}           ;行選択
        Send,^+{+}              ;行追加
        BlockInput,off
        return                  ;挿入モードには移行しない。
      }
    }

    BlockInput,on
    Send,{end}
    Send,{end}
    gosub,insert_start
    gosub,input_enter
    BlockInput,off
    return

  ;1行挿入
  +o::
    if visualmode<>0
      return

    IfWinActive ahk_class XLMAIN    ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61          ;セル外
      {
        BlockInput,on
        IME_SET(0)
        Send,+{Space}           ;行選択
        Send,^+{+}              ;行追加
        BlockInput,off
        return                  ;挿入モードには移行しない。
      }
    }
    BlockInput,on
    Send,{Home}
    Send,{Home}                     ;インデント込みの行頭ではなく、物理行頭まで
    gosub,insert_start
    gosub,input_enter
    Send,{Up}
    BlockInput,off
    return

  t::
    IfWinActive ahk_class XLMAIN    ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61          ;セル外
      {
        BlockInput,on
        IME_SET(0)
        Send,{Right}
        Send,^{Space}           ;列選択
        Send,^+{+}              ;列追加
        BlockInput,off
        return                  ;挿入モードには移行しない。
      }
    }
    ;send,t
    return

  +t::
    IfWinActive ahk_class XLMAIN    ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61          ;セル外
      {
        BlockInput,on
        IME_SET(0)
        Send,^{Space}           ;列選択
        Send,^+{+}              ;列追加
        BlockInput,off
        return                  ;挿入モードには移行しない。
      }
    }
    ;send,+t
    return

  ;1文字変更
  s::
    BlockInput,on
    Send,{Delete}
    gosub,insert_start
    BlockInput,off
    return

  ;1行変更
  +s::
    BlockInput,on
    Send,{Home}
    Send,+{End}
    Send,{Delete}
    gosub,insert_start
    BlockInput,off
    return

  ;行末まで変更
  +c::
    BlockInput,on
    Send,+{End}
    Send,{Delete}
    gosub,insert_start
    BlockInput,off
    return

  ;################################
  ;変更モード
  ;################################
  r::
    IfWinActive ahk_class XLMAIN    ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61          ;セル外
      {
        Send,{F2}               ;セル内の編集に入る
        ;Send,^{Home}
        return
      }
    }

    vimode=4    ;ツールチップ表示用にコマンドモードへ変更
    command=5   ;#ifで他のマップに判定されないように
          ;（他のマップに判定されると、inputよりもホットキーの方が優先される）
    commandline=r
    input, temp, 'B C L1', {ESC} ^h ^[ ^@,      ;^@はULE4JIS時用
    ;msgbox,%ErrorLevel%
    if ErrorLevel=Max
    {
      BlockInput,on
      Send,+{Right}
      Send,{%temp%}
      Send,{Left}
      BlockInput,off
    }
    gosub,mode_end
    return

  +r::
    IfWinActive ahk_class XLMAIN        ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61              ;セル外
      {
        gosub,excel_f2_vim
        return
      }
    }

    vimode=7                            ;置換モード
    if GetKeyState("Ins","T")=0         ;トグル状態が0(押されていない)場合
    {
      Send,{insert}
    }
    return


  ;################################
  ;visualモード（範囲選択開始）
  ;################################
  v::
    if visualmode<>0                    ;選択中
    {
      visualmode=0                  ;選択解除
      gosub,select_cancel
    }
    else
    {
      visualmode=1
      ;デフォルトで1文字選択
      Send,+{Right}
      IfWinActive ahk_class XLMAIN
      {
        ;Excelで、
        ControlGetFocus, temp
        if temp!=EXCEL61        ;セル外
        {
          Send,+{Left}      ;カレントセルだけの選択に戻す。
        }
      }
    }
    return

  ;V 行選択モード
  +v::
    if visualmode=2                 ;既に行選択モード中だった場合
    {
      gosub,select_cancel           ;選択をやめる
      visualmode=0
    }
    else
    {
      visualmode=2
      IfWinActive ahk_class XLMAIN  ;Excel
      {
        ControlGetFocus, temp
        if temp!=EXCEL61        ;セル外
        {
          BlockInput,on
          IME_SET(0)                ;日本語入力OFF。Shift+Spaceで半角空白が入力されないように。
          Send,+{Space}         ;行選択
          BlockInput,off
          return
        }
      }
      BlockInput,on
      Send,{Home}
      Send,+{Down}              ;TODO:最終行では動きがおかしい。Excelのセル外でもダメ。(yy,ddはOK)
      BlockInput,off
    }
    return

  ;矩形選択はアプリによって違うので、とりあえずの対応。Ctrl+vで、そのまま貼り付けが発動する。
  ^v::
    ifWinActive ahk_class TextEditorWindowW166  ;sakuraeditor
    {
      Send,+{F6}
      visualmode=3
    }
    return



  ;################################
  ;コマンド開始(オペレータ待機モード等)
  ;################################
  d::
    BlockInput,on
    if visualmode=0                 ;通常モード
    {
      vimode=4                  ;モーション待ち
      command=1                 ;削除
      commandline=d
    }
    if (visualmode=1 or visualmode=3 )  ;選択中
    {
      Send,^x                       ;クリップボードにカットして、
      gosub,select_cancel           ;範囲選択を解除。
      yankmode=0                    ;バッファが行単位でないことを指定。
    }
    if visualmode=2                 ;行選択中
    {
      Send,^x                       ;クリップボードにカットして
      gosub,select_cancel           ;範囲選択を解除
      Send,{Home}                   ;カーソルを行頭に
      yankmode=1                    ;バッファは行単位
    }
    visualmode=0
    BlockInput,off
    return

  y::
    BlockInput,on
    if visualmode=0                 ;通常モードの場合
    {
      vimode=4                  ;モーション待ち
      command=2                 ;ヤンク
      commandline=y
    }
    if (visualmode=1 or visualmode=3 )  ;選択中
    {
      Send,^c                       ;クリップボードにコピーして、
      gosub,select_cancel           ;範囲選択を解除
      yankmode=0                    ;バッファが行単位でないことを指定。
    }
    if visualmode=2                 ;行選択中
    {
      Send,^c                       ;クリップボードにコピーして
      gosub,select_cancel           ;範囲選択を解除
      Send,{Home}                   ;カーソルを行頭に
      yankmode=0                    ;バッファは行単位
    }
    visualmode=0
    BlockInput,off
    return

  g::                                   ; g : 今のところ、gg専用。
    vimode=4
    command=3
    commandline=g
    return

  z::                                   ; z : 今のところ、zh,zl専用。
    vimode=4
    command=6
    commandline=z
    return

  c::
    IfWinActive ahk_class XLMAIN    ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61          ;セル外
      {
        BlockInput,on
        Send,{Delete}           ;中身を消して、
        Send,{F2}               ;セル内の編集に入る。
        gosub,insert_start      ;挿入モードに遷移
        BlockInput,off
        return
      }
    }

    if visualmode<>0                ;範囲選択している場合
    {
      BlockInput,on
      Send,{Delete}             ;張り付けたい事が多いので、クリップボードはそのままで削除
      gosub,insert_start            ;挿入モード
      BlockInput,off
    }
    vimode=4
    command=4
    commandline=c
    return

  ;################################
  ;クリップボード操作
  ;################################
  x::
    ;エクセルのセル外の場合、内容をコピーしてから内容削除
    IfWinActive ahk_class XLMAIN
    {
      ControlGetFocus, temp
      if temp!=EXCEL61      ;セル外
      {
        BlockInput,on
        Send,{F2}
        Send,^{home}
        Send,+^{End}
        Send,^c
        Send,{ESC}
        Send,{Delete}
        BlockInput,off
        return
      }
    }
    BlockInput,on
    if visualmode=0
      Send,+{Right}
    Send,^x
    gosub,mode_end
    BlockInput,off
    return

  +x::                                  ; X : BackSpace
    BlockInput,on
    if visualmode=0                     ;文字選択中でない場合
      Send,+{Left}                  ;カーソル位置の1文字を
    Send,^x                             ;カット
    gosub,mode_end
    BlockInput,off
    return

  +d::                                  ; D : 行末まで削除
    BlockInput,on
    if visualmode=0                     ;選択中でない場合
      Send,+{End}                       ;行末まで選択
    else
    {                                   ;選択中の場合（再現不可）
      Send,{Home}                       ;カーソルの存在する行の行頭から（本当は、visual開始位置の行からをカットしたい）
      Send,{Home}                       ;
      Send,+{End}                       ;行末まで選択
    }
    Send,^x                             ;カット
    gosub,mode_end
    BlockInput,off
    return

  p::
    if yankmode=0                       ;バッファが文字単位の場合
    {
      IfWinActive ahk_class XLMAIN  ;Excelの、
      {
        ControlGetFocus, temp
        if temp!=EXCEL61            ;セル外
        {                           ;値貼り付けをする。
          BlockInput,on
          settimer,draw_tooltip ,off
          Send,!e                   ;普通に張り付けたい場合は、Ctrl+VやShift+Insertを使うように。
          Send,!s
          WinWaitActive,形式を選択して貼り付け,,3
          if ErrorLevel=0           ;タイムアウトしなければ実行
          {
            Send,!v
            Send,{Enter}
          }
          settimer,draw_tooltip ,%vDraw_tooltip%
          BlockInput,off
          return
        }
      }
      BlockInput,on
      Send,{Right}                  ;カーソルの右側に TODO:行末にカーソルがあると、次の行の行頭になってしまう。。
      Send,^v                           ;張り付ける。
      ;Send,{Left}                  ;大抵は、張り付けた文字列末尾にカーソルがいってしまうので、戻る必要はない。
      BlockInput,off
    }
    else if yankmode=1                  ;バッファが行単位の場合
    {
      IfWinActive ahk_class XLMAIN  ;Excelの、
      {
        ControlGetFocus, temp
        if temp!=EXCEL61            ;セル外
        {                           ;行追加して貼り付け。
          BlockInput,on
          Send,{Down}               ;1行下に
          IME_SET(0)                ;日本語入力OFF。Shift+Spaceで半角空白が入力されないように。
          Send,+{Space}         ;行選択
          Send,^+{+}                ;行貼り付け(Ctrl+Shift+"+")
          BlockInput,off
          return
        }
      }
      BlockInput,on
      Send,{Home}
      Send,{Home}
      Send,{Down}   ;1行下に
      Send,^v       ;張り付ける
      Send,{Up}
      BlockInput,off
    }
    else if yankmode=2                  ;矩形。何基準？
    {
      BlockInput,on
      Send,{Down}
      Send,+{Space}
      Send,+{F10}
      Send,e
      BlockInput,off
    }
    return

  +p::
    if yankmode=0                       ;文字単位の場合
    {
      Send,^v
      ;Send,{Left}
    }
    else if yankmode=1                  ;行単位の場合
    {
      IfWinActive ahk_class XLMAIN  ;Excelの、
      {
        ControlGetFocus, temp
        if temp!=EXCEL61            ;セル外
        {                           ;行追加して貼り付け。
          BlockInput,on
          IME_SET(0)                ;日本語入力OFF。Shift+Spaceで半角空白が入力されないように。
          Send,+{Space}         ;行選択
          Send,^+{+}                ;行貼り付け(Ctrl+Shift+"+")
          BlockInput,off
          return
        }
      }
      BlockInput,on
      Send,{Home}
      Send,{Home}
      Send,^v
      Send,{Up}
      BlockInput,off
    }
    else if yankmode=2
    {
      BlockInput,on
      Send,+{Space}
      Send,+{F10}
      Send,e
      BlockInput,off
    }
    return

  ;################################
  ;数値指定(開始)※2桁目移行は別途
  ;################################
  1::
  2::
  3::
  4::
  5::
  6::
  7::
  8::
  9::
    vimode=3
    ;vimode=4
    ;command=0
    n_count=%A_ThisHotkey%
    return

  ;################################
  ;コマンドラインモード
  ;################################
  :::
  +;::                                      ;日本語キーボードにHHK等を繋いで、ULE4JISしている時用の暫定対処。
    vimode=5                                ;ツールチップ表示変更と、inputboxに文字が入力できるように。
    inputbox ex_commandline ,vimode:,,,,100 ;コマンド入力
    if ErrorLevel = 0                       ;OK
      gosub,run_command
    gosub,mode_end
    return

  ;################################
  ;検索
  ;################################
  /::
    BlockInput,on
    Send,^f
    sleep,20
    gosub,insert_start
    BlockInput,off
    return

  ;?::

  +h::
  +,::
    IfWinActive ahk_class XLMAIN
    {
      ;Excel上ではシート移動
      send,^{PgUp}
    }
    return

  +l::
  +.::
    IfWinActive ahk_class XLMAIN
    {
      ;Excel上ではシート移動
      send,^{PgDn}
    }
    return

  .::
    IfWinActive ahk_class XLMAIN
    {
      if temp!=EXCEL61                  ;セル外
      {
        send,{F4}
        return
      }
    }
    return

  ;不要キー抑止（汎用的に再現不可な物や、未実装で間違えて押しちゃってウザイもの）
  n:: return    ;次を検索
  +n:: return   ;前を検索
  m:: return    ;マークセット
  ':: return    ;マークジャンプ
  q::return ;マクロ記録
  @::return ;マクロ実行
  ;t::return    ;文字検索(直前)
  f::return ;文字検索(直前)
  ,::return ;文字検索(次)

  ; セミコロンエンターを使うのでコメントアウト
  ; `;::return    ;文字検索(前)

  ;^t::return   ;タグスタック
  ;^w::return   ;ウィンドウ系
  ^w::
    IfWinActive ahk_class XLMAIN        ;Excelの閉じるは素通し。
      send,^w
    IfWinActive ahk_class IEFrame       ;IEの閉じるも素通し
      send,^w
    return

  ;*a::
  ;*b::
  ;*c::
  ;*d::
  ;*e::
  ;*f::
  ;*g::
  ;*h::
  ;*i::
  ;*j::
  ;*k::
  ;*l::
  ;*m::
  *n::
  ;*o::
  ;*p::
  *q::
  ;*r::
  ;*s::
  ;*t::
  ;*u::
  ;*v::
  ;*w::
  ;*x::
  ;*y::
  ;*z::
    return

#If
;}}}

;####################################################################
;挿入モード or 置換モード
;####################################################################
;{{{
#if ( vimode=2 or vimode=7)

  ESC::
  ^[::
    if vimode=7 ;置換モードだった場合は、
    {
      if GetKeyState("Ins","T")=1           ;トグル状態が1(押されている)
        Send,{insert}                   ;insertキーを押してエディタのモードを挿入モードに戻す。
    }

    ;todo imeがオンの場合、入力キャンセルせずにinsertモードが終る or 入力キャンセルしてinsertモードが終る の二択。
    ; IME OFF時、インサートモード終了としたい。エクセル上だとセルまで抜ける←対応済み
    gosub,input_escape
    return


  ^h::Send,{BS}

  ;^i::                             ;TABよりもカナ指定を優先
  ; if IME_GET()=1                      ;日本語入力(edgeのテキストボックス上だと判定できない)
  ; {
  ;     ;msgbox,hoge
  ;     Send,^i                     ;Ctrl+iでカナ指定
  ;     return
  ;
  ; }
  ;     ;msgbox,fuga
  ; Send,{Tab}
  ; return

  ; ^j::
  ; ^m::     ;マウスモードへ移行
  ; ^m::
  enter::
    gosub,input_enter
    return

  ^m::
    vimode=8                            ;mouseモード
    return

  ;インデント(カーソル位置が保持できないので使い道が無いかも)
  ^t::
    BlockInput,on
    Send,{Home}
    Send,{Tab}
    BlockInput,off
    return

  ;補完(エディタによる)
  ;^n::
  ;^p::

  ^Enter::
    send,^{Enter}                       ;素通しするが
    IfWinActive ahk_class XLMAIN        ;Excelの
    {
      if temp=EXCEL61                   ;セル内の場合、
      {
        gosub,mode_end              ;セルから出るので、通常モードに戻るように。
        return
      }
    }
    return
#if
;}}}

;####################################################################
;数字入力と、それ以降の処理
;####################################################################
;{{{
#if ( vimode=3 )
  ESC::
  ^[::
    gosub,input_escape
    return

  BS::
  ^h::
    StringLen, len, n_count
    len--
    ;MsgBox, %len%
    if len = 0
      gosub,mode_end
    else
      StringLeft, n_count, n_count, %len%
    return

  ;################################
  ;数値入力
  ;################################
  1::
  2::
  3::
  4::
  5::
  6::
  7::
  8::
  9::
  0::
    n_count=%n_count%%A_ThisHotkey%
    return

  ;################################
  ;カーソル移動
  ;################################
  h::
  j::
  k::
  l::
  w::
  e::
  b::
  +::
  -::
  $::                   ;TODO: n行下の行末までに対応したい
  ^f::
  ^b::
    loop %n_count%
    {
      gosub,move_cursor
    }
    n_count=
    gosub,mode_end
    return



  ;################################
  ;変更
  ;################################
  s::
    loop %n_count%
    {
      Send,+{Right}
    }
    n_count=
    BlockInput,on
    Send,^x
    gosub,mode_end
    gosub,insert_start
    BlockInput,off
    return

  ;################################
  ;置換
  ;################################
  r::
    vimode=31 ;ツールチップ表示、マップ隔離
    commandline=r
    input, temp, 'B C L1', {ESC} ^h ^[ ^@,      ;^@はULE4JIS時用
    if ErrorLevel=Max
    {
      BlockInput,on
      loop %n_count%
      {
        Send,+{Right}
      }
      loop %n_count%
      {
        Send,{%temp%}
      }
      Send,{Left}
      BlockInput,off
    }
    n_count=
    gosub,mode_end
    return

  ;################################
  ;削除
  ;################################
  x::
    BlockInput,on
    loop %n_count%
    {
      Send,+{Right}
    }
    n_count=
    Send,^x
    gosub,mode_end
    BlockInput,off
    return
  +x::
    BlockInput,on
    loop %n_count%
    {
      Send,+{Left}
    }
    n_count=
    Send,^x
    gosub,mode_end
    BlockInput,off
    return

  ;################################
  ;指定行ジャンプ
  ;################################
  g::
    IfWinActive ahk_class Hidemaru32Class
    {
      BlockInput,on
      Send,^g
      Send,%n_count%
      n_count=
      Send,{Enter}
      BlockInput,off
      return
    }
    return

#if
;}}}

;####################################################################
; オペレータd
;####################################################################
;{{{
#if ( vimode=4 and command=1 )
  ESC::
  ^[::
    gosub,input_escape
    return

  d::                                       ;dd : 行削除
    IfWinActive ahk_class XLMAIN        ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61
      {                             ;セル外
        BlockInput,on
        IME_SET(0)                  ;直接入力に（オフにしないと、セル内に半角空白が入るだけなので）
        Send,+{space}               ;行選択して
        Send,^x                     ;カット
        gosub,mode_end              ;オペレータ待機終了
        yankmode=1                  ;バッファが行単位
        BlockInput,off
        return
      }
    }
    BlockInput,on
    Send,{Home}                         ;行頭へ移動
    Send,+{Down}                        ;次の行頭まで選択
    Send,^x                             ;カット
    gosub,mode_end                      ;オペレータ待機終了
    yankmode=1                          ;バッファが行単位
    BlockInput,off
    return

  ;################################
  ;数値入力
  ;################################
  1::
  2::
  3::
  4::
  5::
  6::
  7::
  8::
  9::
    n_count=%n_count%%A_ThisHotkey%
    return

  0::
    if n_count=
    {                           ;初回の"0"は行頭まで
      BlockInput,on
      yankmode=0
      visualmode=1
      gosub,move_0
      Send,^x
      gosub,mode_end
      BlockInput,off
    }else                       ;数値入力中
    {
      n_count=%n_count%%A_ThisHotkey%
    }
    return


  ;################################
  ;範囲削除
  ;################################
  h::
  ^h::
  j::
  k::
  l::
  w::
  e::
  b::
  +::
  -::
  $::                   ; n行下の行末までに対応したい
  ^::
    BlockInput,on
    yankmode=0
    visualmode=1

    if n_count=
      n_count=1
    loop %n_count%
    {
      gosub,move_cursor
    }
    n_count=

    Send,^x
    gosub,mode_end
    BlockInput,off
    return

  *a::
  ;*b::
  *c::
  ;*d::
  ;*e::
  *f::
  *g::
  ;*h::
  *i::
  ;*j::
  ;*k::
  ;*l::
  *m::
  *n::
  *o::
  *p::
  *q::
  *r::
  *s::
  *t::
  *u::
  *v::
  ;*w::
  *x::
  *y::
  *z::
    return

#if
;}}}
;####################################################################
; オペレータy
;####################################################################
;{{{
#if ( vimode=4 and command=2 )
  ESC::
  ^[::
    gosub,input_escape
    return

  v::
    return  ;yを押したがいいが、やっぱりvisualに戻りたくて、vを押しちゃったりした場合に備えて、無視。

  Enter::
    ;y{Enter}は行単位コピーだが、Excelでセルの外にいる場合、現在範囲をコピーするように。
    IfWinActive ahk_class XLMAIN
    {
      ControlGetFocus, temp
      if temp!=EXCEL61          ;セル外
      {
        yankmode=0
        Send,^c
        gosub,mode_end
        return
      }
    }
    else
      gosub,mode_end                ;y<Enter>は何もしない。
    return


  y::                                   ;yy : 行単位コピー

    IfWinActive ahk_class XLMAIN    ;excelで行選択コピー
    {
      ControlGetFocus, temp
      if temp!=EXCEL61          ;セル外
      {
        BlockInput,on
        IME_SET(0)              ;日本語入力モードだとおかしくなる(セル内に半角スペース入力)ため、OFFに。
        Send,+{space}           ;1行選択
        Send,^c                 ;コピー
        gosub,mode_end          ;オペレータ待機終了
        yankmode=1              ;カットバッファの中身が行単位であることを保持
        BlockInput,off
        return
      }
    }
    BlockInput,on
    Send,{Home}                     ;行頭から
    Send,+{Down}                    ;行末まで。{End}ではないのは、改行込みでコピーしたいため。※最終行がEOFだとうまく作用しない。
    Send,^c                         ;コピー
    Send,{Up}                       ;カーソル位置を戻す。
    gosub,mode_end
    yankmode=1                      ;カットバッファの中身が行単位であることを保持
    BlockInput,off
    return

  ;################################
  ;数値入力
  ;################################
  1::
  2::
  3::
  4::
  5::
  6::
  7::
  8::
  9::
    n_count=%n_count%%A_ThisHotkey%
    return

  0::
    if n_count=
    {                           ;初回の"0"は行頭まで
      BlockInput,on
      yankmode=0
      visualmode=1
      gosub,move_0
      Send,^c                       ;コピー
      gosub,mode_end
      BlockInput,off
    }else                       ;数値入力中
    {
      n_count=%n_count%%A_ThisHotkey%
    }
    return


  ;################################
  ;範囲コピー
  ;################################
  h::
  ^h::
  j::
  k::
  l::
  w::
  e::
  b::
  +::
  -::
  $::                   ;TODO: n行下の行末までに対応したい
  ^::
    BlockInput,on
    yankmode=0                  ;バッファが行単位でないことを指定。
    visualmode=1                ;コピーするために範囲選択開始。

    if n_count=
      n_count=1
    loop %n_count%
    {
      gosub,move_cursor     ;指定された範囲まで移動
    }
    n_count=

    Send,^c                     ;コピー
    gosub,select_cancel         ;範囲選択を解除。
    gosub,mode_end
    BlockInput,off
    return

  *a::
  *b::
  *c::
  ;*d::
  ;*e::
  *f::
  *g::
  ;*h::
  *i::
  ;*j::
  ;*k::
  ;*l::
  *m::
  *n::
  *o::
  *p::
  *q::
  *r::
  *s::
  *t::
  *u::
  *v::
  ;*w::
  *x::
  ;*y::
  *z::
    return
#if
;}}}

;####################################################################
; オペレータc
;####################################################################
;{{{
#if (vimode=4 and command=4 )
  ESC::
  ^[::
    gosub,input_escape
    return

  ;1行変更(Sと同じ)
  c::
    BlockInput,on
    Send,{Home}
    Send,+{End}
    Send,{Delete}
    gosub,insert_start
    BlockInput,off
    return

  ;################################
  ;数値入力
  ;################################
  1::
  2::
  3::
  4::
  5::
  6::
  7::
  8::
  9::
    n_count=%n_count%%A_ThisHotkey%
    return

  0::
    if n_count=
    {                           ;初回の"0"は行頭まで
      BlockInput,on
      yankmode=0
      visualmode=1
      gosub,move_0
      Send,^x
      gosub,mode_end
      gosub,insert_start
      BlockInput,off
    }else                       ;数値入力中
    {
      n_count=%n_count%%A_ThisHotkey%
    }
    return


  h::
  ^h::
  j::
  k::
  l::
  w::
  e::
  b::
  +::
  -::
  $::                   ;TODO: n行下の行末までに対応したい
  ^::
    BlockInput,on
    yankmode=0
    visualmode=1

    if n_count=
      n_count=1
    loop %n_count%
    {
      gosub,move_cursor
    }
    n_count=

    Send,^x
    gosub,mode_end
    gosub,insert_start
    BlockInput,off
    return

  *a::
  *b::
  ;*c::
  ;*d::
  ;*e::
  *f::
  *g::
  ;*h::
  *i::
  ;*j::
  ;*k::
  ;*l::
  *m::
  *n::
  *o::
  *p::
  *q::
  *r::
  *s::
  *t::
  *u::
  *v::
  ;*w::
  *x::
  *y::
  *z::
    return
#if
;}}}

;####################################################################
; 'g'で始まるコマンド g gg gf gm
;       ※gX のXと関係がない機能はこっちに
;####################################################################
;{{{
#if ( vimode=4 and command=3 )
  ESC::
  ^[::
  BS::
  ^h::
    gosub,input_escape
    gosub,mode_end
    return

  g::
    if visualmode =0
      Send,^{Home}
    else
      Send,+^{Home}
    gosub,mode_end
    return

  f::                                           ;ファイルを開く
    ;msgbox,"gf!"
    gf_enable=0
    IfWinActive ahk_class XLMAIN            ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61                  ;セル外
      {
        if visualmode=0                 ;範囲選択していない
          gf_enable=1
      }
      else                              ;セル内
      {
        if visualmode!=0                ;範囲選択している
          gf_enable=1
        else
          gf_enable=2
      }
    }
    else                                    ;Excel以外
    {
      if visualmode!=0
        gf_enable=1
      else
        gf_enable=2
    }

    if gf_enable=0                          ;gf不可の場合、終了
    {
      gosub,mode_end
      return
    }

    BlockInput,on
    if gf_enable=1                          ;選択範囲をコピーするだけ
      Send,^c

    if gf_enable=2                          ;行頭～行末をコピーしてみる
    {
      Send,{Home}
      Send,+{End}
      Send,^c
    }

    settimer,draw_tooltip ,off
    Send,#r             ;Win-R
    sleep,100
    WinWaitActive ,ファイル名を指定して実行,実行するプログラム名、または,3
    if ErrorLevel=0         ;もし、3秒待ってもアクティブにならなかったらやらない。
    {
      Send,^v               ;貼り付け
      Send,{Enter}      ;実行
    }
    settimer,draw_tooltip ,%vDraw_tooltip%
    gosub,mode_end
    BlockInput,off
    return

  m::                                           ;gm : セルマージ
    IfWinActive ahk_class XLMAIN            ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61                  ;セル外
      {
        BlockInput,on
        Send,!h
        Send,!m
        Send,!m
        BlockInput,off
      }
    }
    gosub,mode_end
    return

  +m::                                      ;gM : セルマージ解除
    IfWinActive ahk_class XLMAIN            ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61                  ;セル外
      {
        BlockInput,on
        Send,!h
        Send,!m
        Send,!u
        BlockInput,off
      }
    }
    gosub,mode_end
    return

  o::                                           ;go 外枠罫線
    IfWinActive ahk_class XLMAIN            ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61                  ;セル外
      {
        BlockInput,on
        Send,!h
        Send,!b
        Send,!s
        BlockInput,off
      }
    }
    gosub,mode_end
    return

  i::                                           ;gi 格子罫線
    IfWinActive ahk_class XLMAIN            ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61                  ;セル外
      {
        BlockInput,on
        Send,!h
        Send,!b
        Send,!a
        BlockInput,off
      }
    }
    gosub,mode_end
    return

  n::                                           ;gn 格子なし
    IfWinActive ahk_class XLMAIN            ;Excel
    {
      ControlGetFocus, temp
      if temp!=EXCEL61                  ;セル外
      {
        BlockInput,on
        Send,!h
        Send,!b
        Send,!n
        BlockInput,off
      }
    }
    gosub,mode_end
    return

  r::                                           ; gr :
    IfWinActive ahk_class XLMAIN            ;Excelで、
    {                                       ;
      BlockInput,on
      settimer,draw_tooltip ,off
      Send,!h                               ;ホーム
      Send,!o                               ;書式
      Send,!h                               ;行の高さ
      WinWaitActive,行の高さ
      IME_SET(0)
      WinWaitNotActive,行の高さ
      settimer,draw_tooltip ,%vDraw_tooltip%
      gosub,mode_end
      BlockInput,off
    }
    return

  +r::                                      ; gR :
    IfWinActive ahk_class XLMAIN            ;Excelで、
    {                                       ;
      BlockInput,on
      Send,+{Space}                     ;行選択
      Send,!h                               ;ホーム
      Send,!o                               ;書式
      Send,!a                               ;行の高さの自動調整
      gosub,mode_end
      BlockInput,off
    }
    return

  c::                                           ; gc :
    IfWinActive ahk_class XLMAIN            ;Excelで、
    {                                       ;
      BlockInput,on
      settimer,draw_tooltip ,off
      Send,!h                               ;ホーム
      Send,!o                               ;書式
      Send,!w                               ;列の幅
      WinWaitActive,列の幅
      IME_SET(0)
      WinWaitNotActive,列の幅
      settimer,draw_tooltip ,%vDraw_tooltip%
      gosub,mode_end
      BlockInput,off
    }
    return

  +c::                                      ; gc :
    IfWinActive ahk_class XLMAIN            ;Excelで、
    {                                       ;
      BlockInput,on
      Send,^{Space}                     ;列選択
      Send,!h                               ;ホーム
      Send,!o                               ;書式
      Send,!i                               ;列の幅の自動調整
      gosub,mode_end
      BlockInput,off
    }
    return

  z::                                           ; gz :ズーム
    IfWinActive ahk_class XLMAIN            ;Excelで、
    {                                       ;
      BlockInput,on
      settimer,draw_tooltip ,off
      Send,!w                               ;表示
      Send,!q                               ;ズーム
      WinWaitActive,ズーム
      Send,!c
      IME_SET(0)
      WinWaitNotActive,ズーム
      settimer,draw_tooltip ,%vDraw_tooltip%
      gosub,mode_end
      BlockInput,off
    }
    return

  *a::
  *b::
  ;*c::
  *d::
  *e::
  ;*f::
  ;*g::
  ;*h::
  ;*i::
  *j::
  *k::
  *l::
  ;*m::
  ;*n::
  ;*o::
  *p::
  *q::
  ;*r::
  *s::
  *t::
  *u::
  *v::
  *w::
  *x::
  *y::
  ;*z::
    return


#if
;}}}

;####################################################################
; 'z'で始まるコマンド zh zl   TODO:回数指定はできない。。
;       ※zX のXと関係のある機能はこっちに
;####################################################################
;{{{
#if ( vimode=4 and command=6 )
  ESC::
  ^[::
  BS::
  ^h::
    BlockInput,on
    gosub,input_escape
    gosub,mode_end
    BlockInput,off
    return

  h::                                           ; zh :
    IfWinNotActive ahk_class XLMAIN         ;Excel以外で、
    {
      if visualmode!=0                  ;選択している時は、カーソル移動できないので何もしない。
        return
    }

    BlockInput,on
    GetKeyState temp ,ScrollLock,T          ;スクロールロック
    if temp=U                               ;してなければ、
      Send,{ScrollLock}                 ;して、
    Send,{Left}                             ;左に移動して、
    Send,{ScrollLock}                       ;スクロールロック解除
    gosub,mode_end
    BlockInput,off
    return

  l::                                           ; zl :
    IfWinNotActive ahk_class XLMAIN         ;Excel以外で、
    {
      if visualmode!=0                  ;選択している時は、カーソル移動できないので何もしない。
        return
    }

    BlockInput,on
    GetKeyState temp ,ScrollLock,T          ;スクロールロック
    if temp=U                               ;してなければ、
      Send,{ScrollLock}                 ;して、
    Send,{Right}                            ;右に移動して、
    Send,{ScrollLock}                       ;スクロールロック解除
    gosub,mode_end
    BlockInput,off
    return


  f::
    ;ついgfと間違えて押してしまうのでとりあえず無効化。TODO:zfの折り畳み作成は、いずれExcelのグループ化等を行うように。
    gosub,mode_end
    return

  *a::
  *b::
  *c::
  *d::
  *e::
  ;*f::
  *g::
  ;*h::
  *i::
  *j::
  *k::
  ;*l::
  *m::
  *n::
  *o::
  *p::
  *q::
  *r::
  *s::
  *t::
  *u::
  *v::
  *w::
  *x::
  *y::
  *z::
    return

#if
;}}}

;####################################################################
; コマンドラインモード
;####################################################################
;{{{
#if ( vimode=5 )
  ESC::
  ^[::
  :::
    gosub,mode_end
    return

  ;IfWinActive ahk_class #32770
  ;{
  ;}
#if
;}}}

;####################################################################
; コマンド実行
;####################################################################
;{{{
run_command:
  IfEqual ex_commandline                ;空文字は何もしない
    return
  else if ex_commandline = w
    Send,^s
  ;else if ex_commandline = x           ;実現方式も思いつかないし、大抵閉じるときに保存するか聞いてくるので不要。
  ; Send,^w
  else if ex_commandline = q
  {
    IfWinActive ahk_class XLMAIN    ;excel
    {
      Send,^w                       ;ブックを閉じる
      return
    }
    ifWinActive ahk_class IEFrame   ;ieの場合
    {
      Send,^w                       ;タブを閉じる
      return
    }
    Send,!{F4}
  }
  else
  {
    ;todo 未実装色々
    msgbox, %ex_commandline% は未実装です。
  }
  return
;}}}

;####################################################################
; マウスモード
;####################################################################
;{{{
#if ( vimode=8 )

  ESC::                     ;
  ^[::
  ;^m::
    ;gosub,mode_end         ;右クリックメニューを閉じようとしてモード終了してしまう
    Send,{ESC}              ;単純にESC送出するだけでOK。マウスモード終了は、iやoに任せる。
    return

  ;左クリックダウン
  Space::
    MouseClick,LEFT,,,,,D
    return

  ;左クリックアップ
  Space up::
    MouseClick,LEFT,,,,,U
    return

  ;左ダブルクリック
  Enter::
    MouseClick,LEFT,,,2,,
    return


  ;右クリックダウン
  :::
  `;::
    MouseClick,RIGHT,,,,,D
    return

  ;右クリックアップ
  : up::
  `; up::
    MouseClick,RIGHT,,,,,U
    return

  ;拡張クリック
  ,::MouseClick,X1
  .::MouseClick,X2


  ;左クリックして、カーソルを合わせてから、マウスモードを抜ける。
  i::
    MouseClick,LEFT
    gosub,mode_end
    return

  ;左クリックして、カーソルを合わせてから、挿入モードへ
  +i::
    MouseClick,LEFT
    gosub,mode_end
    vimode=2
    return

  ;通常モード
  o::gosub,mode_end

  ;挿入モード
  +o::
    gosub,mode_end
    vimode=2
    return

  ;クリップボード
  y::Send,^c
  x::Send,^x
  p::Send,^v


  ;カーソル移動の加減速用
  a::return
  s::return
  d::return
  f::return

  ;カーソル移動
  h::
    mmovex=-%vMouse_move%
    mmovey=0
    if GetKeyState("j","P") = 1
      mmovey=%vMouse_move%
    if GetKeyState("k","P") = 1
      mmovey=-%vMouse_move%
    gosub,mouse_move
    return
  j::
    mmovex=0
    if GetKeyState("h","P") = 1
      mmovex=-%vMouse_move%
    if GetKeyState("l","P") = 1
      mmovex=%vMouse_move%
    mmovey=%vMouse_move%
    gosub,mouse_move
    return
  k::
    mmovex=0
    if GetKeyState("h","P") = 1
      mmovex=-%vMouse_move%
    if GetKeyState("l","P") = 1
      mmovex=%vMouse_move%
    mmovey=-%vMouse_move%
    gosub,mouse_move
    return
  l::
    mmovex=%vMouse_move%
    mmovey=0
    if GetKeyState("j","P") = 1
      mmovey=%vMouse_move%
    if GetKeyState("k","P") = 1
      mmovey=-%vMouse_move%
    gosub,mouse_move
    return

  !h::Send,!{Left}
  !l::Send,!{Right}


  ;ホイール回転
  r & h::MouseClick,WL
  r & j::MouseClick,WD
  r & k::MouseClick,WU
  r & l::MouseClick,WR

  ;キーリピートによるスクロール(通常モードに戻るのがめんどくさい時用)
  g & h::Send,{Left}
  g & j::Send,{Down}
  g & k::Send,{Up}
  g & l::Send,{Right}

  ;Excelのシート選択（通常モードと同じものを再定義）
  +h::
  +,::
    IfWinActive ahk_class XLMAIN
    {
      ;Excel上ではシート移動
      send,^{PgUp}
    }
    return

  +l::
  +.::
    IfWinActive ahk_class XLMAIN
    {
      ;Excel上ではシート移動
      send,^{PgDn}
    }
    return

mouse_move:
    if GetKeyState("a","P")=1
    {
      mmovex/=%vMouse_move%
      mmovey/=%vMouse_move%
    }
    if GetKeyState("s","P")=1
    {
      mmovex/=2
      mmovey/=2
    }
    if GetKeyState("d","P")=1
    {
      mmovex*=2
      mmovey*=2
    }
    if GetKeyState("f","P")=1
    {
      mmovex*=5
      mmovey*=5
    }
    ;tooltip,%mmovex% | %mmovey%
    MouseMove,%mmovex%,%mmovey%,0,R
    return

#if
;}}}

;####################################################################
;カーソル移動系
;####################################################################
;{{{
move_h:
  if ( visualmode=0 or visualmode=3 )
    Send,{Left}
  else if visualmode=1
    Send,+{Left}
  return

move_j:
  if ( visualmode=0 or visualmode=3 )
    Send,{Down}
  else if visualmode=1
    Send,+{Down}
  else if visualmode=2
  {
    Send,+{Down}
    Send,+{End}
  }
  return

move_k:
  if ( visualmode=0 or visualmode=3 )
    Send,{Up}
  else  if visualmode=1
    Send,+{Up}
  else if visualmode=2
  {
    BlockInput,on
    Send,+{UP}
    Send,+{Home}
    BlockInput,off
  }
  return

move_l:
  if ( visualmode=0 or visualmode=3 )
    Send,{Right}
  else if visualmode=1
    Send,+{Right}
  return

move_w:
  if ( visualmode=0 or visualmode=3 )
    Send,^{Right}
  else if visualmode=1
    Send,^+{Right}
  return

move_e:
  if ( visualmode=0 or visualmode=3 )
  {
    BlockInput,on
    Send,{Right}
    Send,^{Right}
    Send,{Left}
    BlockInput,off
  }
  else if visualmode=1
  {
    BlockInput,on
    Send,+{Right}
    Send,^+{Right}
    Send,+{Left}
    BlockInput,off
  }
  return

move_b:
  if ( visualmode=0 or visualmode=3 )
    Send,^{Left}
  else if visualmode=1
    Send,^+{Left}
  return

move_0:
  if ( visualmode=0 or visualmode=3 )
  {
    BlockInput,on
    Send,{Home}
    Send,{Home}
    BlockInput,off
  }
  else if visualmode=1
  {
    BlockInput,on
    Send,+{Home}
    Send,+{Home}
    BlockInput,off
  }
  return

move_$:
  if ( visualmode=0 or visualmode=3 )
    Send,{End}
  else if visualmode=1
    Send,+{End}
  return

move_^:
  if ( visualmode=0 or visualmode=3 )
    Send,{Home}
  else if visualmode=1
    Send,+{Home}
  return

move_+:
  if ( visualmode=0 or visualmode=3 )
  {
    BlockInput,on
    Send,{Home}
    Send,{Down}
    BlockInput,off
  }
  else if visualmode=1
  {
    BlockInput,on
    Send,{Home}
    Send,{Down}
    BlockInput,off
  }
  return

move_-:
  if ( visualmode=0 or visualmode=3 )
  {
    BlockInput,on
    Send,{Home}
    Send,{Up}
    BlockInput,off
  }
  else if visualmode=1
  {
    BlockInput,on
    Send,+{Home}
    Send,+{Up}
    BlockInput,off
  }
  return

move_^f:                                        ;次ページ
  if ( visualmode=0 or visualmode=3 )
    Send,{PgDn}
  else if visualmode=1
    Send,+{PgDn}
  return

move_^b:                                        ;前ページ
  if ( visualmode=0 or visualmode=3 )
    Send,{PgUp}
  else                                      ;選択していても（行選択も含む）
  {
    IfWinActive ahk_class XLMAIN            ;Excelの場合は、
      Send,^b                               ;太字にする。 TODO:回数指定で来た場合どうなる？奇数回指定すると太字にならない？
    else
      Send,+{PgUp}
  }
  return

move_^y:                                        ;前行
  IfWinNotActive ahk_class XLMAIN               ;Excel以外で、
  {
    if visualmode!=0                        ;選択している時は、カーソル移動できないので何もしない。
      return
  }

  BlockInput,on
  GetKeyState temp ,ScrollLock,T            ;スクロールロック
  if temp=U                             ;してなければ、
    Send,{ScrollLock}                   ;して、
  Send,{Up}                             ;上に移動して、
  Send,{ScrollLock}                     ;スクロールロック解除
  BlockInput,off
  return


move_^e:                                        ;次行
  IfWinNotActive ahk_class XLMAIN               ;Excel以外で、
  {
    if visualmode!=0                        ;選択している時は、カーソル移動できないので何もしない。
      return
  }

  BlockInput,on
  GetKeyState temp ,ScrollLock,T            ;スクロールロック
  if temp=U                             ;してなければ、
    Send,{ScrollLock}                   ;して、
  Send,{Down}                               ;下に移動して、
  Send,{ScrollLock}                     ;スクロールロック解除
  BlockInput,off
  return

move_cursor:
  if      A_ThisHotkey = h
    gosub,move_h
  else if A_ThisHotkey = j
    gosub,move_j
  else if A_ThisHotkey = k
    gosub,move_k
  else if A_ThisHotkey = l
    gosub,move_l
  else if A_ThisHotkey = w
    gosub,move_w
  else if A_ThisHotkey = e
    gosub,move_e
  else if A_ThisHotkey = b
    gosub,move_b
  else if A_ThisHotkey = +
    gosub,move_+
  else if A_ThisHotkey = -
    gosub,move_-
  else if A_ThisHotkey = 0
    gosub,move_0
  else if A_ThisHotkey = ^
    gosub,move_^
  else if A_ThisHotkey = $
    gosub,move_$
  else if command=0 ;カット、ヤンク等には頁移動は含まない
  {
    if      A_ThisHotkey = ^f
      gosub,move_^f
    else if A_ThisHotkey = ^b
      gosub,move_^b
  }
  return
;}}}

;####################################################################
;Enter押下時処理
;####################################################################
;{{{
input_enter:
  BlockInput,on
  if vimode=1                                       ;通常モード
  {
    IfWinActive ahk_class XLMAIN                ;Excel
    {
      ControlGetFocus, temp
      if temp=EXCEL61                           ;セル内
      {
        if A_ThisHotkey = o
          Send,!{Enter}                 ;セル内改行を行う。
        else if A_ThisHotkey = +o
          Send,!{Enter}                 ;セル内改行を行う。
        else
          Send,{down}                       ;カーソルを下へ
      }
      else{                                 ;セル外
        Send,{Enter}                        ;Enter素通し
      }
      BlockInput,off
      return                                    ;Excelの場合はここで終了。
    }
    else                                        ;Excel以外は
      Send,{down}                               ;カーソルを下へ

    BlockInput,off
    return                                      ;通常モードの場合は、ここまでで終了
  }

                          ;以下、通常モード以外の場合
  IfWinActive ahk_class XLMAIN                  ;excelの場合
  {
    ControlGetFocus, temp
    if temp=EXCEL61                             ;セル内
    {

      if IME_GET()=1                            ;日本語入力中
      {
        sleep,90                            ;Space直後の変換中にEnterを押した場合に備えて、少々待機。
        if IME_GetConverting()!=0           ;変換中だった場合は、
          Send,{Enter}                  ;確定
        else                                ;変換中かどうかわからない（未入力状態、または、候補窓無しで未確定）場合
        {
          ;msgbox,変換中ではない？
          Send,+{Space}                 ;Shift+Space(ただのSpaceだと変換内容が変わってしまうので)を入力して、
          sleep,90                      ;しばし待つ。
          if IME_GetConverting()!=0     ;候補窓が出た場合（未確定文字列あり）
            Send,{Enter}                ;確定
          else                          ;候補窓が出なかった場合（未確定文字列なし）
          {
            Send,+{Space}                   ;もう一発、Shift+Space
            sleep,90                        ;しばし待つ。
            if IME_GetConverting()!=0       ;候補窓が出た場合（実は未確定文字列ありだった！）
              Send,{Enter}              ;確定
            else
            {
              Send,{BS}                 ;Shift+Spaceで半角空白が入力されてしまっているはずななので、BSで消してから、
              Send,{BS}                 ;
              Send,!{Enter}             ;セル内改行を行う。
            }
          }
        }
      }
      else                                  ;直接入力時は、セル内改行(Alt-Enter)
        Send,!{Enter}

    }
    else            ;セル外
      Send,{enter}
  }
  else              ;excel以外
  {
    Send,{enter}
  }
  BlockInput,off
  return
;}}}

;####################################################################
;ESC押下時処理
;####################################################################
;{{{
input_escape:
  if visualmode!=0                              ;選択中
  {
    gosub,select_cancel
    gosub,mode_end                              ;解除
    return
  }

  BlockInput,on

  ;EXCELの場合、ESC連打でセルの編集内容が有無を言わせず失われてしまうのを予防
  IfWinActive ahk_class XLMAIN                  ;Excel
  {
    ControlGetFocus, temp
    if temp=EXCEL61                             ;セル内
    {
      if vimode=1                               ;通常モードの場合
      {
        Send,^{Enter}                       ;カーソル位置そのままセル内容を確定
      }
      else                                  ;挿入モード以外（挿入モード等）
      {
        if IME_GET()=1                      ;日本語入力
        {
          if IME_GetConverting()!=0     ;候補窓が出ている
            Send,{ESC}                  ;候補窓取消
          else                          ;候補窓が出ていない
          {
            Send,+{Space}               ;Shift+Space
            sleep,90                    ;
            if IME_GetConverting()!=0   ;候補窓が出た場合（未確定文字列あり）
            {
              Send,{ESC}                ;候補窓取消
              Send,{ESC}                ;未確定文字列キャンセル
            }
            else                        ;候補窓が出ない（未確定文字列なし）
            {
              Send,{BS}
              gosub,mode_end            ;通常モードに
            }
          }
        }else{                              ;直接入力時
          gosub,mode_end                    ;通常モードに
        }
      }
    }
    else                                        ;Excelのセル外
      if vimode=4                               ;入力待ちの場合
        gosub,mode_end                      ;ノーマルモードに戻る。
      else
        Send,{ESC}
  }
  else  ;エクセル以外
  {
    if vimode=1                                 ;通常モード
      Send,{ESC}                                ;ESC
    else
    {
      if IME_GET()=1 and IME_GetConverting()!=0 ;日本語入力中(Excelのセル内と違って、正しく判定できる)
      {
        Send,{ESC}
      }else{
        gosub,mode_end
      }
    }
  }

  BlockInput,off
  return
;}}}

;####################################################################
;挿入モード開始
;####################################################################
;{{{
insert_start:
  BlockInput,on
  ;エクセルの場合、セルの外だったらセル編集に
  ;TODO:テキストボックスなどのオブジェクトとセル外の区別が付かない。
  IfWinActive ahk_class XLMAIN                  ;Excel
  {
    ControlGetFocus, temp
    if temp!=EXCEL61                            ;セル外
    {
      Send,{F2}
      if A_ThisHotkey = i
      {
        Send,^{Home}
      }
    }
  }
  vimode=2
  BlockInput,off
  return
;}}}

;####################################################################
; 通常モードに戻る
;####################################################################
;{{{
mode_end:
  IME_SET(0)
  vimode=1
  visualmode=0
  yankmode=0
  command=0
  n_count=
  commandline=
  BlockInput,off
  return
;}}}

;####################################################################
; 選択解除
;####################################################################
;{{{
select_cancel:
  IfWinActive ahk_class Hidemaru32Class
  {
    ;Send,{Esc}
    ;選択開始位置に戻る
    Send,{Left}
    return
  }
  IfWinActive ahk_class XLMAIN                  ;Excel
  {
    ControlGetFocus, temp
    if temp!=EXCEL61                            ;セル外
    {
      BlockInput,on
      Send,{Left}
      Send,{Right}
      BlockInput,off
      return
    }
  }
  ;選択開始位置に戻る
  Send,{Left}
  return
;}}}

;####################################################################
;Excelのセル編集をgvimで行う
;####################################################################
;{{{
excel_f2_vim:
  BlockInput,on
  WinGetActiveTitle ,myTitle
  Send,{F2}             ;セル内に入って、
  sleep,10
  Send,^{End}               ;全選択
  Send,+^{Home}
  Send,^c                   ;コピー
  sleep,50

  ;msgbox %A_WorkingDir%
  FileDelete vimode_excel_work.txt              ;ワークファイル削除
  Clipboard=%Clipboard%                         ;テキスト以外の形式を、テキスト形式に変換
  FileAppend,%Clipboard%,vimode_excel_work.txt  ;クリップボード内容をワークファイル書き込み
  sleep,100
  RunWait,gvim.exe vimode_excel_work.txt            ;gvim起動。pathは通っている前提。終了待ち
  WinActivate ,%myTitle%
  ControlGetFocus, temp
  if temp!=EXCEL61                              ;もし、セル外に出てしまっていたら
  {
    Send,{F2}                                   ;入りなおして
    Send,^{End}                                 ;全選択
    Send,+^{Home}
  }
  FileRead,Clipboard,vimode_excel_work.txt      ;ワークファイルをクリップボードに読み込み
  FileDelete vimode_excel_work.txt              ;ワークファイル削除
  Send,^v                                           ;貼り付け
  Send,^{Enter}                                 ;セルを抜ける
  BlockInput,off
  return
;}}}
