#WinActivateForce
#Include %A_ScriptDir%
#Include IME.ahk

;; 「無変換」=「英数」単体でオフになるように
; sc07b::
;  IME_SET(0)
; return

; sc079::
; sc070:: ; Input
; 「無変換」でトグルする
sc07b::
  if (IME_GET() == 0)
  {
    IME_SET(1)
  }
  else
  {
    IME_SET(0)
  }
; 音声入力で日本語を入力を行うことになったので、skkのモード切り替えのキーストロークが不要になった。
; とりあえず CorvusSKK を引き続き使うことにするが、Windows 11 との相性なのか AutoHotKey との問題なのか、
; ときどきちゃんと変換が動かなくなるので、しばらくは様子見する。
; Send, ^j
return

;; 設定のリロード
;; sc07b & r::Reload

;; https://hattomo.github.io/posts/main/21/q1/0223-autohotkey-mac/
;; ChangeKey で mac の Cmd の位置に Ctrl, CapsLock を F13 にした上での設定
;; http://did2.blog64.fc2.com/blog-entry-349.html

;; F13 (CapsLock) を使って Emacs 的なキーバインドを実現する
;; Windows Terminal や VSCode を例外にしない
F13 & a::Send,{Blind}{Home}
F13 & b::Send,{Blind}{Left}
F13 & c::Send,^c
F13 & d::Send,{Blind}{Delete}
F13 & e::Send,{Blind}{End}
F13 & f::Send,{Blind}{Right}
F13 & g::Send,^g
F13 & h::Send,{Blind}{Backspace}
F13 & i::Send,{Blind}{Tab}
F13 & j::^j
F13 & k::Send,+{End}{Shift}+{Delete}
F13 & l::^l
F13 & m::Send,{Blind}{Enter}
F13 & n::Send,{Blind}{Down}
F13 & o::^o
F13 & p::Send,{Blind}{Up}
F13 & q::^q
F13 & r::^r
F13 & s::^s
F13 & t::Send,^t ;; IdeaVim で戻る
F13 & u::Send,^u
F13 & v::Send,^v
F13 & w::Send,^w
F13 & x::Send,^x
F13 & y::Send,^y
F13 & z::Send,^z
F13 & [::Send,{Blind}{Esc}
F13 & ]::Send,^] ;; IdeaVim でシンボル移動
F13 & Enter::Send,^{Enter}

;; 特定のアプリのときだけ F13 を Ctrl にするのはうまくいかなかった
;; Windows Terminal で入れ替えると tmux が使えない
;; #IfWinActive ahk_exe WindowsTerminal.exe
;;   F13::Ctrl
;; #IfWinActive

;; Ctrl (Cmd) 二度押しで PowerToys Run 起動
;; Raycast の起動方法にあわせた
;; https://annin102.hatenadiary.jp/entry/20080415/1208271705
~LCtrl up::
  if(A_PriorHotKey = A_ThisHotKey and A_TimeSincePriorHotkey < 400)
  {
    Send, !+{Space}
  }
Return

;; F3 でミッションコントロールみたいに Win-Tab 表示にする
F3::#Tab
F13 & Up::#Tab
F13 & Down::#Tab
; !Tab だダメ
; LCtrl & Tab::AltTabMenu
LCtrl & Tab::AltTab

;; macOS では Raycast のクリップボード履歴を使っている
!v::Send,#v

; 無変換+タブで Alt+Tab 置き換え。キーボードだけでフォーカス切り替えするには Win+Tab より都合がいい。
sc07b & Tab::AltTab

; h, j, k, l で移動させたかったので IME on/off のキーバインディングを変更
sc07b & h::Send, {Left}
sc07b & j::Send, {Down}
sc07b & k::Send, {Up}
sc07b & l::Send, {Right}
sc07b & 0::Send, {Home}
sc07b & 4::Send, {End}

sc07b & e::Send, +9
sc07b & r::Send, +0
sc07b & d::Send, +[
sc07b & f::Send, +]
sc07b & c::Send, [
sc07b & v::Send, ]

sc07b & t::Send, -
sc07b & y::Send, +=
sc07b & g::Send, =
sc07b & b::Send, +-
sc07b & o::Send, \
sc07b & p::Send, +\

sc07b & m::Send, {Enter}
sc07b & [::Send, {Esc}
sc07b & ,::Send, {BackSpace}
sc07b & n::Send, {BackSpace}
sc07b & i::Send, {Tab}

; 無変換 + z で Win+z (スナップツール) 起動割り当て
; sc07b & z::#z
; sc07b & a::#a
; Windows 10 なので意味がない
; sc07b & n::#n
; sc07b & x::#x
; sc07b & s::#s
; sc07b & c::^c
; sc07b & x::^x
; sc07b & t::^t
; sc07b & w::^w
; sc07b & v::#v
; sc07b & .::#h ; 音声入力, 右手の押しやす目のキーで . に
; sc07b & Space::#Space

; expand という意味で割当しなおし。
; sc07b & e::Send, ^+x ;; Teams 用。Ctrl+Shift+X より打ちやすい。

;^+k::AltTabAndMenu     ;alt+tab    ※3キーは無理？

; sc07b & d::
; ;; $^+k::
; Send,#{Tab} ;デスクトップ切り替え
; return

; ;
; ; Alt+Tab タスク切り替え中
; #IfWinActive ahk_class MultitaskingViewFrame
;   !h::!Left
;   !j::!Down
;   !k::!Up
;   !l::!Right
;   !d::!Delete
; #IfWinActive
;
; ;Win+Tabのデスクトップ切り替え
; #IfWinActive ahk_class XamlExplorerHostIslandWindow ahk_exe Explorer.EXE
;   h::Left
;   j::Down
;   k::Up
;   l::Right
;   `;::Enter
;   w:: ;右のデスクトップへ(ジャンプリスト時は何もしない)
;     ifWinActive ,タスク ビュー ;ahkファイルは、UTF-8のBOM付きにしておかないと、上手く判定されないので注意。
;     {
;       BlockInput,on
;       Send,+{Tab}
;       Send,{Right}
;       Send,{Space}
;       Send,{Tab}
;       BlockInput,off
;     }
;   return
;   b:: ;左のデスクトップへ(ジャンプリスト時は何もしない)
;     ifWinActive ,タスク ビュー
;     {
;       BlockInput,on
;       Send,+{Tab}
;       Send,{Left}
;       Send,{Space}
;       Send,{Tab}
;       BlockInput,off
;     }
;   return
; #IfWinActive
;
; ;
; ;タスクバーで右クリックしたジャンプリスト（最近使ったもの）
; #IfWinActive ahk_class Windows.UI.Core.CoreWindow ahk_exe ShellExperienceHost.exe
;   j::Down
;   k::Up
;   `;::Enter
;   ESC::
;   ^h::
;     BlockInput,on
;     Send,{Esc}
;     Send,#{t}
;     BlockInput,off
;   return
; #IfWinActive
; ;
; ;Win+T タスクバー
; #IfWinActive ahk_class Shell_TrayWnd
;   h::Left
;   j::return ;なにもしない（Ctrl+Shift+Jで入ってくるので反応してしまう）
;   k::Up ;プレビュー
;   l::Right
;   w::
;     BlockInput,on
;     Send,{Right} ;右のアプリのプレビュー
;     Send,{Up}
;     BlockInput,off
;   return
;   b:: ;左のアプリのプレビュー
;     BlockInput,on
;     Send,{Left}
;     Send,{Up}
;     BlockInput,off
;   return
;   `;::
;   :::
;     Send,{AppsKey} ;ジャンプリスト表示
;   return
; #IfWinActive
; ;
; ;Win+T タスクバーのプレビュー
; #IfWinActive ahk_class TaskListThumbnailWnd
;   h::Left
;   l::Right
;   j::Down ;タスクバーへ戻る
;   w::
;     BlockInput,on
;     Send,{Down} ;右のアプリのプレビュー
;     Send,{Right}
;     Send,{Up}
;     BlockInput,off
;   return
;   b:: ;左のアプリのプレビュー
;     BlockInput,on
;     Send,{Down}
;     Send,{Left}
;     Send,{Up}
;     BlockInput,off
;   return
;   Enter:: Send,{Enter} ;選択
;   x::
;     BlockInput,on
;     Send,{AppsKey}
;     sleep,200 ;右クリックメニューが出るまで時間がかかるのか、cが空振る事がある。
;     Send,c
;     BlockInput,off
;   return
; #IfWinActive
;
