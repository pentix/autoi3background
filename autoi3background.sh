#!/bin/bash
# (c) 2019 github.com/pentix/autoi3background
# GPL v3 

success () {
    printf "\033[0;32m$1\033[0m\n"
}

c=$(convert $1 -resize 1x1\! -format "%[fx:int(255*r+.5)],%[fx:int(255*g+.5)],%[fx:int(255*b+.5)]" info:-)
r=$(echo $c | cut -f1 -d,)
g=$(echo $c | cut -f2 -d,)
b=$(echo $c | cut -f3 -d,)

average=$(printf "#%02x%02x%02x\n" $r $g $b)
new_conf_line_str="client.focused $average $average"

current_setting=$(grep -P "^client.focused " ~/.config/i3/config)
conf_line_str="client.focused "$(echo "$current_setting" | cut -f2 -d' ')" "$(echo "$current_setting" | cut -f3 -d' ')

echo "Current setting:         " $(echo $conf_line_str)
echo "Suggested new setting:   " $(echo $new_conf_line_str)
echo ""

printf "Do you want to proceed? [y|n]  "
read y

if [[ "$y" == "y" ]]
then
    cp ~/.config/i3/config{,_before_autoi3background.bak}
    sed -i "s|$conf_line_str|$new_conf_line_str|g" ~/.config/i3/config
    success "Configuration adjusted :)\n"
    
    printf "Do you want to restart i3? [y|n]  "
    read y
    
    if [[ "$y" == "y" ]]
    then
        i3-msg restart
        success "Restarted i3 :)"
    fi
fi

success "Exiting..."
