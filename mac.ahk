#WinActivateForce
#Include %A_ScriptDir%
#Include IME.ahk

;; 「無変換」=「英数」単体でオフになるように
sc07b::
    IME_SET(0)
    return

;; 「かな」単体でオンになるように
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
