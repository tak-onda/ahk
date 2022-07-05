#WinActivateForce
#Include %A_ScriptDir%
#Include IME.ahk

;; 「無変換」=「英数」単体でオフになるように
sc07b::
    IME_SET(0)
    return

;; 「変換」「かな」単体でオンになるように
sc079::
sc070:: ; Input
    IME_SET(1)
    ; 音声入力で日本語を入力を行うことになったので、skkのモード切り替えのキーストロークが不要になった。
    ; とりあえず CorvusSKK を引き続き使うことにするが、Windows 11 との相性なのか AutoHotKey との問題なのか、
    ; ときどきちゃんと変換が動かなくなるので、しばらくは様子見する。
    Send, ^j
    return

;; F3 でミッションコントロールみたいに Win-Tab 表示にする
F3::#Tab

;; VSCode や Windows Terminal, JetBrains でないときは emacs モード使いたい
;; ^h::Send, {BackSpace}
;; ^m::Send, {Enter}
;; ^a::Send, {Home}
;; ^a::Send, {Home}
;; ^f::Send, {Right}

;; 設定のリロード
sc07b & r::Reload

;; Enter と Backspace だけは押しやすく
^m::Send,{Enter}
^h::Send,{Backspace}
^[::Send,{Esc}

; 無変換+タブで Alt+Tab 置き換え。キーボードだけでフォーカス切り替えするには Win+Tab より都合がいい。
sc07b & Tab::AltTab

; h, j, k, l で移動させたかったので IME on/off のキーバインディングを変更
sc07b & h::Send, {Left}
sc07b & j::Send, {Down}
sc07b & k::Send, {Up}
sc07b & l::Send, {Right}
sc07b & 0::Send, {Home}
sc07b & 4::Send, {End}

; 無変換 + z で Win+z (スナップツール) 起動割り当て
sc07b & z::#z
sc07b & a::#a
sc07b & n::#n
; sc07b & x::#x
sc07b & s::#s
sc07b & c::^c
sc07b & x::^x
sc07b & v::#v
sc07b & .::#h ; 音声入力, 右手の押しやす目のキーで . に

; expand という意味で割当しなおし。
sc07b & e::Send, ^+x ;; Teams 用。Ctrl+Shift+X より打ちやすい。

sc07b & t::
;; $^+j::
  Send,#t           ;タスクバー
  return

;^+k::AltTabAndMenu     ;alt+tab    ※3キーは無理？

sc07b & d::
;; $^+k::
  Send,#{Tab}       ;デスクトップ切り替え
  return

;
; Alt+Tab タスク切り替え中
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

;
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
;
;Win+T タスクバー
#IfWinActive ahk_class Shell_TrayWnd
  h::Left
  j::return             ;なにもしない（Ctrl+Shift+Jで入ってくるので反応してしまう）
  k::Up                 ;プレビュー
  l::Right
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
  `;::
  :::
    Send,{AppsKey}      ;ジャンプリスト表示
    return
#IfWinActive
;
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
