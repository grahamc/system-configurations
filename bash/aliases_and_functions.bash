source ~/.config/bash/complete_alias
make_alias_and_enable_autocomplete() {
	if [ $# -ne 2 ]; then
			echo -e "\e[31mError: Two arguments are required, the alias name and the command it should be expanded to. \nExample: ${FUNCNAME[0]} la 'ls -a'\e[m" >>/dev/stderr
			return 1
	fi

	alias "$1"="$2"
	# If the function is defined, call it
	[[ "$(declare -fF _complete_alias)" ]] && complete -F _complete_alias "$1";
}
make_alias_and_enable_autocomplete 'r' "source ~/.bashrc && hash -r"
make_alias_and_enable_autocomplete 'r-desktop-entries' 'update-desktop-database ~/.local/share/applications'
make_alias_and_enable_autocomplete 'r-xbindkeys' 'killall xbindkeys; xbindkeys'
make_alias_and_enable_autocomplete 'r-kitty' 'reload-kitty'
make_alias_and_enable_autocomplete 'r-asdf' 'asdf reshim'
make_alias_and_enable_autocomplete 'r-tmux' 'tmux source ~/.tmux.conf && tmux display-message "Reloaded TMUX..."'
make_alias_and_enable_autocomplete 'r-tmux-plugins' "$HOME/.tmux/plugins/tpm/bindings/install_plugins"
r_tmux_server() {
	if tmux list-sessions &> /dev/null; then
		# save server state before killing it
		~/.tmux/plugins/tmux-resurrect/scripts/save.sh
		tmux kill-server
	fi

	tmux
}
make_alias_and_enable_autocomplete 'r-tmux-server' 'r_tmux_server'
make_alias_and_enable_autocomplete 'r-tmux-pane' 'tmux respawn-pane -k'
make_alias_and_enable_autocomplete 'trash' 'trash-put'
make_alias_and_enable_autocomplete 'pbcopy' 'xclip -selection clipboard'
make_alias_and_enable_autocomplete 'pbpaste' 'xclip -selection clipboard -o'
make_alias_and_enable_autocomplete 'ls' 'ls --classify'
make_alias_and_enable_autocomplete 'la' 'ls -a'
make_alias_and_enable_autocomplete 'll' 'ls -l'
make_alias_and_enable_autocomplete 'lal' 'ls -al'
make_alias_and_enable_autocomplete 'tree' 'rg --color=never --files | \tree --fromfile  .'
# Quick way to reconnect to tmux after a restart/closed-terminal.
# This command connects to a running session, or if there isn't one, it just
# launches tmux, in which case tmux-resurrect should restore the entire tmux environment
make_alias_and_enable_autocomplete 'ta' 'tmux attach-session -t main &> /dev/null || tmux attach-session &> /dev/null || tmux'
tunnel() { cloudflared tunnel run --url "http://localhost:$1"; }
mktouch() { mkdir -p "$(dirname "$1")" && touch "$1" ; }
make_alias_and_enable_autocomplete 'sai' 'sudo apt install'
make_alias_and_enable_autocomplete 'sar' 'sudo apt remove'
make_alias_and_enable_autocomplete 'saar' 'sudo apt autoremove'
make_alias_and_enable_autocomplete 'ap' 'apt policy'
make_alias_and_enable_autocomplete 'sau' 'sudo apt update'
bd() { cd `command bd "$@"`; }
cd() { command cd "$@" && ls; }
make_alias_and_enable_autocomplete 'sudo' 'sudo '
