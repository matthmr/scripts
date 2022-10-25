bindkey -e

# Fixes the shitty implementation of word boundary in Emacs mode
autoload -U select-word-style
select-word-style bash
