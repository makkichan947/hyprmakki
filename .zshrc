eval "$(starship init zsh)"

#语法检查和高亮
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

#开启tab上下左右选择补全
zstyle ':completion:*' menu select
autoload -Uz compinit
compinit

# 设置历史记录文件的路径
HISTFILE=~/.zsh_history

# 设置在会话（内存）中和历史文件中保存的条数，建议设置得大一些
HISTSIZE=1000
SAVEHIST=1000

# 忽略重复的命令，连续输入多次的相同命令只记一次
setopt HIST_IGNORE_DUPS

# 忽略以空格开头的命令（用于临时执行一些你不想保存的敏感命令）
setopt HIST_IGNORE_SPACE

# 在多个终端之间实时共享历史记录
# 这是实现多终端同步最关键的选项
setopt SHARE_HISTORY

# 让新的历史记录追加到文件，而不是覆盖
setopt APPEND_HISTORY
# 在历史记录中记录命令的执行开始时间和持续时间
setopt EXTENDED_HISTORY

yy() {
    local tmp=$(mktemp -t "yazi-cwd.XXXXXX")
    yazi "$@" --cwd-file="$tmp"
    local cwd=$(cat -- "$tmp")
    rm -f -- "$tmp"
    if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
}

recovery-pacman() {
	pacman "$@" \
	--log /dev/null \
	--noscriptlet \
	--dbonly \
	--overwrite "*" \
	--nodeps \
	--needed
}

export HF_ENDPOINT=https://hf-mirror.com

# 设置别名
alias ll='ls -lah'
alias cddoc='cd /home/Hausmeister/文档'
alias syyu='sudo pacman -Syyu'
alias lghs='last -F | less'
alias py='python3'

echo "Now Login User:" | figlet | lolcat;whoami | figlet | lolcat

date | lolcat
cal | lolcat
