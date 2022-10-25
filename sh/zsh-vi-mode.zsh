bindkey -v

bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char
bindkey -M menuselect '^[[Z' reverse-menu-complete
bindkey -M vicmd '?' history-incremental-search-forward
bindkey -M vicmd '/' history-incremental-search-backward

bindkey ^U backward-kill-line
bindkey ^K kill-line

bindkey "^P" history-incremental-pattern-search-backward
bindkey "^N" history-incremental-pattern-search-forward
