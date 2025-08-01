if status is-interactive
  set fish_greeting
  set -Ux EDITOR /usr/bin/nvim
  set -Ux GOPATH $HOME/.cache/go
  set -Ux GOBIN $HOME/.local/bin
  alias lg='lazygit'
  alias edit='chezmoi edit'
  alias tmux='zellij'
  starship init fish | source
end
