#!/usr/bin/env bash
# ssh-cfg.sh - list the ssh commands implied by ~/.ssh/config and run one.

CONFIG="${SSH_CONFIG:-$HOME/.ssh/config}"
PATTERN=""

usage() {
    cat <<USAGE
Usage: ${0##*/} [-g PATTERN] [-h]

Parse $CONFIG, list every ssh command it implies (sorted and
numbered), then prompt for a number and run the matching command.

Options:
  -g, --grep PATTERN   Only list commands matching PATTERN (case-insensitive,
                       grep basic regex). Also accepts --grep=PATTERN.
  -h, --help           Show this help and exit.

Environment:
  SSH_CONFIG           Use this file instead of ~/.ssh/config.

Notes:
  - One command is listed per Host alias (wildcard Host patterns are skipped).
  - Honored keywords: HostName, User, Port, IdentityFile, IdentitiesOnly,
    HostKeyAlgorithms. Include directives are not followed.
  - At the prompt enter a number to connect, or q (or an empty line) to quit.
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -g|--grep)
            if [ $# -lt 2 ]; then echo "error: $1 requires a pattern" >&2; usage >&2; exit 2; fi
            PATTERN="$2"; shift 2 ;;
        --grep=*) PATTERN="${1#--grep=}"; shift ;;
        *) echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [ ! -r "$CONFIG" ]; then
    echo "error: cannot read $CONFIG" >&2
    exit 1
fi

# One line per Host alias: "<display command>\t<arg1>\x1f<arg2>\x1f..."
parse() {
    awk '
    function flush(   i, args, disp) {
        for (i = 1; i <= n; i++) {
            args = ""; disp = "ssh"
            if (key != "")  { args = args "-i\037" key "\037";  disp = disp " -i " key }
            if (port != "" && port != "22") { args = args "-p\037" port "\037"; disp = disp " -p " port }
            if (ident != "") { args = args "-o\037IdentitiesOnly=" ident "\037"; disp = disp " -o IdentitiesOnly=" ident }
            if (hka != "")  { args = args "-o\037HostKeyAlgorithms=" hka "\037"; disp = disp " -o HostKeyAlgorithms=" hka }
            if (host != "") { tgt = (user != "" ? user "@" : "") host }
            else            { tgt = aliases[i] }
            args = args tgt; disp = disp " " tgt
            printf "%s\t%s\n", disp, args
        }
        n = 0; host = user = port = key = hka = ident = ""
    }
    { sub(/\r$/, "") }
    /^[ \t]*(#|$)/ { next }
    {
        k = tolower($1)
        if (k == "host") {
            flush()
            for (i = 2; i <= NF; i++) {
                if ($i ~ /^#/) break
                if ($i !~ /[*?!]/) aliases[++n] = $i
            }
        } else if (k == "match") { flush() }
        else if (k == "hostname" && host == "")  host = $2
        else if (k == "user" && user == "")      user = $2
        else if (k == "port" && port == "")      port = $2
        else if (k == "identityfile" && key == "") key = $2
        else if (k == "identitiesonly" && ident == "") ident = $2
        else if (k == "hostkeyalgorithms" && hka == "") hka = $2
    }
    END { flush() }
    ' "$CONFIG"
}

LIST=$(parse | LC_ALL=C sort -u)
if [ -n "$PATTERN" ]; then
    LIST=$(printf '%s\n' "$LIST" | grep -i -- "$PATTERN")
fi

if [ -z "$LIST" ]; then
    echo "no matches" >&2
    exit 1
fi

DISPLAY_LINES=()
ARGLINES=()
while IFS=$'\t' read -r disp args; do
    DISPLAY_LINES+=("$disp")
    ARGLINES+=("$args")
done <<EOT
$LIST
EOT

total=${#DISPLAY_LINES[@]}
i=0
while [ "$i" -lt "$total" ]; do
    printf '%4d) %s\n' "$((i + 1))" "${DISPLAY_LINES[$i]}"
    i=$((i + 1))
done

while :; do
    printf 'Enter number [1-%d] (q to quit): ' "$total"
    if ! read -r choice; then echo; exit 0; fi
    case "$choice" in
        ""|q|Q) exit 0 ;;
        *[!0-9]*) echo "invalid selection: $choice" >&2; continue ;;
    esac
    if [ "$choice" -lt 1 ] || [ "$choice" -gt "$total" ]; then
        echo "invalid selection: $choice" >&2
        continue
    fi
    break
done

idx=$((choice - 1))
IFS=$'\037' read -r -a SSH_ARGS <<<"${ARGLINES[$idx]}"
echo "+ ${DISPLAY_LINES[$idx]}" >&2
exec ssh "${SSH_ARGS[@]}"
