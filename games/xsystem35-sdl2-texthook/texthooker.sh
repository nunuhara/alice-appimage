#!/bin/bash

last_line_empty=no
prev_text=""

while read -r line
do
    # ignore consecutive empty lines
    if [ -z "$line" ] && [ "$last_line_empty" = yes ]; then
        continue
    fi
    # dump text into clipboard when we get an empty line
    if [ -z "$line" ]; then
        last_line_empty=yes
        if [ "$text" != "$prev_text" ]; then
            echo "$text"
            echo "$text" | xclip -selection clipboard
            sleep 0.3
            prev_text="$text"
        fi
        text=""
    else
        last_line_empty=no
    fi
    # remove page number
    # TODO: add option to ignore given page numbers
    #       e.g. xsystem35-texthook --ignore-pages=7,13,17
    line=$(echo "$line" | sed -e 's/^[0-9]*://')
    if [ "$line" == "$prev_text" ]; then
        continue
    fi
    # ignore non-game messages on stdout
    if [[ "$line" = mus_* ]] || [[ "$line" = ev* ]]; then
        continue
    fi
    printf -v text "%s\n%s" "$text" "$line"
done
