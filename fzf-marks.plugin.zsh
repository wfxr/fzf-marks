if [[ -z "$BOOKMARKS_FILE" ]] ; then
    export BOOKMARKS_FILE="$HOME/.bookmarks"
fi

touch "$BOOKMARKS_FILE"

wfxr::bookmarks-fzf() {
    local list
    (( $+commands[exa] )) && list='exa -lbhg --git' || list='ls -l'
    fzf --border \
        --ansi \
        --cycle \
        --reverse \
        --height '40%' \
        --preview="echo {}|sed 's#.*->  ##'| xargs $list --color=always" \
        --preview-window="right:50%" \
        "$@"
}

function mark() {
    [[ "$#" -eq 0 ]] && wfxr::mark_usage && return 1
    local mark_to_add
    mark_to_add=$(echo "$*: $(pwd)")
    echo "${mark_to_add}" >> "${BOOKMARKS_FILE}"

    echo "** The following mark has been added **"
    echo "${mark_to_add}"
}

function dmarks()  {
    local lines
    lines=$(lmarks| wfxr::bookmarks-fzf --query="$*" -m)

    wfxr::bookmarks-delete "$lines"
}

# List all marks
function lmarks() {
    sed 's#: # -> #' "$BOOKMARKS_FILE"| nl| column -t
}

# Prompt user to delete invalid marks
function cleanmarks() {
    local invalid_marks
    invalid_marks=$(lmarks |
        wfxr::bookmarks-invalid |
        wfxr::bookmarks-fzf -m --header='** The following marks are not invalid anymore **')
    wfxr::bookmarks-delete "$invalid_marks"
}

# Delete selected bookmarks
function wfxr::bookmarks-delete() {
    local lines
    lines="$*"
    if [[ -n $lines ]]; then
        echo "$lines" |awk '{print $1}'| sed 's/$/d/'| paste -sd';'| xargs -I{} sed -i "{}" "$BOOKMARKS_FILE"
        echo "** The following marks have been deleted **"
        echo "$lines"
    fi
}

# Show usage for function mark
function wfxr::mark_usage() {
    echo "Usage: mark <bookmark>" >&2
    echo "   eg: mark downloads"
}

# List invalid marks
function wfxr::bookmarks-invalid() {
    local line
    local directory
    while read line; do
        directory=$(echo "$line" |sed 's#.*->  ##')
        test -d "$directory" || echo "$line"
    done
}

function jump() {
    local target
    target=$(lmarks |
        wfxr::bookmarks-fzf --query="$*" -1|
        sed 's#.*->  ##')
    if [[ -d "$target" ]]; then
        cd "$target" && zle reset-prompt
    else
        zle redisplay # Just redisplay if no jump to do
    fi
}

zle -N jump
bindkey ${FZF_MARKS_JUMP:-'^g'} jump
