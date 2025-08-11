if status is-interactive
  set fish_greeting
  set -Ux EDITOR /usr/bin/nvim
  set -Ux GOPATH $HOME/.cache/go
  set -Ux GOBIN $HOME/.local/bin

  if test -f ~/.config/private/config.local.fish
    source ~/.config/private/config.local.fish
  end

  alias lg='lazygit'
  alias edit='chezmoi edit'
  alias tmux='zellij'
  starship init fish | source
end
