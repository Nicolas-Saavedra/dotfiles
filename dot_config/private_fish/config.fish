if status is-interactive
  set fish_greeting
  set -Ux GOPATH $HOME/.cache/go
  set -Ux GOBIN $HOME/.local/bin
  alias lg lazygit
  alias tmux zellij
  starship init fish | source
end
