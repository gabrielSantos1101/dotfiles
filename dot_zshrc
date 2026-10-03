# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells.
# Same bootstrap the ~/.bashrc uses — keeps mise shims + omarchy bins on PATH in zsh.
# (absolute path on purpose: $OMARCHY_PATH is set *by* this file)
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else.
[[ $- != *i* ]] && return

# --- Omarchy shell completions / completion menu ---
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# --- navegação sem 'cd': digita o nome da pasta e entra direto (AUTO_CD nativo do zsh) ---
setopt AUTO_CD
# pilha de diretórios: 'cd -' volta pro anterior, como no bash
setopt AUTO_PUSHD
cdpath=("$HOME" $cdpath)

# --- histórico: precisa Gravar p/ o zsh-autosuggestions ter o que sugerir ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt appendhistory      # grava no arquivo a cada comando
setopt sharehistory        # mantém histórico compartilhado entre shells/zellij
setopt hist_ignore_all_dups
setopt hist_ignore_space   # comando começando com espaço não entra no histórico

# --- fzf (Ctrl+T / Ctrl+R / Alt+C — the same omarchy bash integration) ---
if command -v fzf >/dev/null 2>&1; then
  export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {} 2>/dev/null | head -200'"
  export FZF_ALT_C_OPTS="--walker roots,hidden,follow"
  source /usr/share/fzf/completion.zsh 2>/dev/null
  source /usr/share/fzf/key-bindings.zsh 2>/dev/null
fi

# --- zoxide (smarter cd) ---
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# --- plugins de autocomplete do zsh ---
# syntax highlighting: comandos válidos em verde, inválidos em vermelho
if [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
fi
# autosuggestions: sugere o comando enquanto você digita (seta direita aceita)
if [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# --- aliases que replicam o omarchy bash (via omarchy-shell-default aliases) ---
alias cl='clear'
alias cls='clear'
alias clr='clear'
alias cla='clear'
alias clal='clear -x'
alias clc='clear && printf "\033[2J"'
alias cll='clear -l'
alias clx='clear -x'

alias zd='clear -x && z'
alias zdd='z'
alias zdl='z -l'

alias ll='lsd -lh --group-directories-first --total-size'
alias la='lsd -lah --group-directories-first'
alias lst='lsd --tree --depth=2'

alias clg='clear && git status && git log --oneline -5'
alias clgp='clg && git pull --prune'
alias clgc='clg && git commit -m'
alias clgd='clg && git diff'
alias clgs='clg && git status -sb'

alias t='tmux attach || tmux new -s main'

# --- zellij auto-start (replicado do .bashrc): guard + exec em shell NOVO ---
if [[ -z "$ZELLIJ" ]] && command -v zellij >/dev/null 2>&1 && [[ -n $PS1 ]]; then
  exec zellij
fi

# --- starship prompt initialization ---
eval "$(starship init zsh)"

# NOTE: the omarchy bash rc is intentionally NOT sourced here.
# Sourcing bash's rc into zsh injects a bash-syntax PS1 (renders as literal
# \[\] in zsh, which uses %{}), loads bash-completion over zsh's native
# completion (breaks `cd dir<TAB>` without a trailing slash), and clobbers
# compinit so fresh shells lose the completion cache.

# --- dotfiles sync (chezmoi): capture changes, commit and push ---
# dotfs ja faz o trabalho todo (re-add, commit, pull --rebase, push).
# Com argumento: dotfs "mensagem"   |   sem argumento: abre o editor pro commit.
alias gs='dotfs'
alias gassync='dotfs'
