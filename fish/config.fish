/opt/homebrew/bin/brew shellenv | source

if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting
end

alias hg='history | grep'

fastfetch
