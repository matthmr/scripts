bindkey -v
zmodload zsh/complist

bindkey ^U backward-kill-line
bindkey ^K kill-line

bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect '^[[Z' reverse-menu-complete

bindkey -M vicmd '?' history-incremental-search-forward
bindkey -M vicmd '/' history-incremental-search-backward

bindkey -v '^?' backward-delete-char
echo -ne '\e[1 q' # Use beam shape cursor on startup.

# autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

# bindkey "^P" history-incremental-pattern-search-backward
# bindkey "^N" history-incremental-pattern-search-forward
