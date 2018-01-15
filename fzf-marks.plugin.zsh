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
    local mark_to_add
    mark_to_add=$(echo "$*: $(pwd)")
    echo "${mark_to_add}" >> "${BOOKMARKS_FILE}"

    echo "** The following mark has been added **"
    echo "${mark_to_add}"
}

function dmark()  {
    local line
    line=$(lmarks| wfxr::bookmarks-fzf --query="$*" -m)

    if [[ -n $line ]]; then
        echo "$line" |awk '{print $1}'| xargs -I{} sed -i "{}d" "$BOOKMARKS_FILE"
        echo "** The following marks have been deleted **"
        echo "$line"
    fi
    zle && zle reset-prompt
}

# List all marks
function lmarks() {
    sed 's#: # -> #' "$BOOKMARKS_FILE"| nl| column -t
}

# TODO: Check invalid marks and prompt user to delete them
function checkmarks() {
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
if [ "${FZF_MARKS_DMARK}" ]; then
    zle -N dmark
    bindkey ${FZF_MARKS_DMARK} dmark
fi
