#WinActivateForce
#UseHook, On
#SingleInstance, force
#Include %A_ScriptDir%
#Include IME.ahk

;; 「無変換」=「英数」単体でオフになるように
; sc07b::
;  IME_SET(0)
; return

; LWin「無変換」でトグルする
; Ctrl, Shift は SKK を阻害してしまう
LWin::
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

;; https://blog.kubosho.com/entries/use-autohotkey-to-macos-like-keymapping
;; Thinkpad なら Alt で Keychrone なら左スペースなど macOS の Cmd あたりに F13 をマッピング
F13 & /::^/
F13 & ,::^,
F13 & 1::^1
F13 & 2::^2
F13 & 3::^3
F13 & 4::^4
F13 & 5::^5
F13 & 6::^6
F13 & 7::^7
F13 & 8::^8
F13 & 9::^9
F13 & 0::^0
F13 & a::^a
F13 & b::^b
F13 & c::^c
F13 & f::^f
F13 & h::^h
F13 & i::^i
F13 & k::^k
F13 & l::^l
F13 & n::^n
F13 & p::^p
F13 & q::!F4
F13 & r::^r
F13 & s::^s
F13 & t::^t
F13 & v::^v
F13 & w::^w
F13 & x::^x
F13 & z::^z
F13 & Enter::^Enter
F13 & Space::#s
; https://superuser.com/questions/1246946/autohotkey-remapping-altshifttab-to-lwinshifttab
F13 & Tab::
  AltTabMenu := true
  If GetKeyState("Shift","P")
    Send {Alt Down}{Shift Down}{Tab}
  else
    Send {Alt Down}{Tab}
return

#If (AltTabMenu)
  ~*F13 Up::
    Send {Shift Up}{Alt Up}
    AltTabMenu := false
  return
#If

; Windows keymap
F13 & e::#e
F13 & Up::#Up
F13 & Right::#Right
F13 & Down::#Down
F13 & Left::#Left

#IfWinNotActive, ahk_exe WindowsTerminal.exe
  Return
#IfWinNotActive

; Emacs like keymap
#IfWinNotActive, ahk_exe WindowsTerminal.exe
  ^p::Send, {Up}
  ^f::Send, {Right}
  ^n::Send, {Down}
  ^b::Send, {Left}
  ^+p::Send, {Shift}+{Up}
  ^+f::Send, {Shift}+{Right}
  ^+n::Send, {Shift}+{Down}
  ^+b::Send, {Shift}+{Left}
  ^a::Send, {Home}
  ^e::Send, {End}
  ^d::Send, {Delete}
  ^h::Send, {BackSpace}
  ^m::Send, {Enter}
  ^k::Send, {Shift}+{End}{BackSpace}
  Return
#IfWinNotActive

;; Ctrl (Cmd) 二度押しで PowerToys Run 起動
;; Raycast の起動方法にあわせた
;; https://annin102.hatenadiary.jp/entry/20080415/1208271705
~LCtrl up::
  if(A_PriorHotKey = A_ThisHotKey and A_TimeSincePriorHotkey < 400)
  {
    Send, !+{Space}
  }
Return

~F13 up::
  if(A_PriorHotKey = A_ThisHotKey and A_TimeSincePriorHotkey < 400)
  {
    Send, !+{Space}
  }
Return

;; 特定のアプリのときだけ F13 を Ctrl にするのはうまくいかなかった
;; Windows Terminal で入れ替えると tmux が使えない
;; #IfWinActive ahk_exe WindowsTerminal.exe
;;   F13::Ctrl
;; #IfWinActive

;; F3 でミッションコントロールみたいに Win-Tab 表示にする
F3::#Tab
; !Tab だダメ
; LCtrl & Tab::AltTabMenu
LCtrl & Tab::AltTab

;; macOS では Raycast のクリップボード履歴を使っている
; !v::Send,#v

;; 無変換系の扱いはあらためて考える
;; Esc を割り当てているので、Shift Oneshot で IME on/off を切り替えたい
;; https://snowsystem.net/other/windows/windows-capslock-ctrl-f13-key/
;
; 無変換+タブで Alt+Tab 置き換え。キーボードだけでフォーカス切り替えするには Win+Tab より都合がいい。
;
; sc07b & Tab::AltTab
; h, j, k, l で移動させたかったので IME on/off のキーバインディングを変更
; sc07b & h::Send, {Left}
; sc07b & j::Send, {Down}
; sc07b & k::Send, {Up}
; sc07b & l::Send, {Right}
; sc07b & 0::Send, {Home}
; sc07b & 4::Send, {End}
;
; sc07b & e::Send, +9
; sc07b & r::Send, +0
; sc07b & d::Send, +[
; sc07b & f::Send, +]
; sc07b & c::Send, [
; sc07b & v::Send, ]
;
; sc07b & t::Send, -
; sc07b & y::Send, +=
; sc07b & g::Send, =
; sc07b & b::Send, +-
; sc07b & o::Send, \
; sc07b & p::Send, +\
;
; sc07b & m::Send, {Enter}
; sc07b & [::Send, {Esc}
; sc07b & ,::Send, {BackSpace}
; sc07b & n::Send, {BackSpace}
; sc07b & i::Send, {Tab}
