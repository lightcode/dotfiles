path=(
  /usr/sbin
  /sbin
  $HOME/.local/bin
  $path
)


#########################
# Setup Go environment
#########################

if (( $+commands[go] )) ; then
  export GOPATH="$HOME/go"
  export GOBIN="$GOPATH/bin"
  path=(
    $GOBIN
    $path
  )
fi


#########################
# ALIAS
#########################

alias cal='cal -m'
alias ip='ip -c'
alias o='open'
alias scu='systemctl --user'


#########################
# FUNCTIONS
#########################

mkd() {
  mkdir -p "$@" && cd "$@"
}

open() {
  local args="$*"

  if [[ -z "$args" ]]; then
    args="."
  fi

  xdg-open $args &>/dev/null &!
}
