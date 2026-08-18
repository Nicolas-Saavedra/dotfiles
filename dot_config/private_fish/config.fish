if status is-interactive
  set fish_greeting
  set -Ux EDITOR /usr/bin/nvim
  set -Ux GOPATH $HOME/.cache/go
  set -Ux GOBIN $HOME/.local/bin

  if test -f ~/.config/private/config.local.fish
      source ~/.config/private/config.local.fish
  else
      echo "(no private config loaded)"
  end

  alias lg='lazygit'
  alias dash='gh-dash'
  alias edit='chezmoi edit'
  alias ls='eza'
  alias tree='eza --tree --git-ignore'
  alias opencode='opencode --port'
  alias cd='z'
  alias up='topgrade'
  starship init fish | source
  zoxide init fish | source
end
