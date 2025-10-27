if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting
end

starship init fish | source

alias hg='history | grep'
alias wff='wf-recorder -f ~/Videos/recording_(date +%Y-%m-%d_%H-%M-%S).mp4'
alias wf='wf-recorder -g "$(slurp)" -f ~/Videos/recording_(date +%Y-%m-%d_%H-%M-%S).mp4'

takeoff
fastfetch
