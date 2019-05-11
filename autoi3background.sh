#!/bin/bash
# (c) 2019 github.com/pentix/autoi3background
# GPL v3 

success () {
    printf "\033[0;32m$1\033[0m\n"
}

error () {
    printf "\033[0;31mError: $1\033[0m\n"
}

usage () {
    printf "\033[1mUSAGE:\033[0m $0 \033[4mpath/to/wallpaper.png\033[0m\n"
}

# Check for arguments
if (( $# < 1 ))
then
    error "Too few arguments"
    usage
    exit 1
fi

# Check if provided wallpaper exists
test -e "$1"
if [[ $? != 0 ]]
then
    error "File '$1' does not exist"
    exit 1
fi

# Check if i3 config exists
test -e ~/.config/i3/config
if [[ $? != 0 ]]
then
    error "i3 config seems to missing!"
    exit 1
fi


# Do color magic 
c=$(convert $1 -resize 1x1\! -format "%[fx:int(255*r+.5)],%[fx:int(255*g+.5)],%[fx:int(255*b+.5)]" info:-)
r=$(echo $c | cut -f1 -d,)
g=$(echo $c | cut -f2 -d,)
b=$(echo $c | cut -f3 -d,)

# value between 0 and 255
luminance=$(bc <<< "0.299*$r + 0.587*$g + 0.114*$b")

if (( $(echo "$luminance > 127.5" |bc -l) )); then
	# make text font 70% darker
	text_factor="0.3"
else 
	#make text font 70% brighter
	text_factor="1.7"
fi

# update font colors rgb.
tc_r=$(bc <<< "($r*$text_factor)")
tc_g=$(bc <<< "($g*$text_factor)")
tc_b=$(bc <<< "($b*$text_factor)")

# round & convert to int
tc_r=$(bc <<< " ( $tc_r + 0.5 )/1")
tc_g=$(bc <<< " ( $tc_g + 0.5 )/1")
tc_b=$(bc <<< " ( $tc_b + 0.5 )/1")

# update to an allowed value if overflow
# note that an underflow isn't possible
if (( $(echo "$tc_r > 255"|bc -l) )); then 
	tc_r="255" 
fi

if (( $(echo "$tc_g > 255"|bc -l) )); then 
	tc_g="255" 
fi

if (( $(echo "$tc_b > 255"|bc -l) )); then 
	tc_b="255" 
fi

#hex value of average
average=$(printf "#%02x%02x%02x\n" $r $g $b)
text_average=$(printf "#%02x%02x%02x\n" $tc_r $tc_g $tc_b)

new_conf_line_str="client.focused $average $average $text_average"

current_setting=$(grep -P "^client.focused " ~/.config/i3/config)
conf_line_str="client.focused "$(echo "$current_setting" | cut -f2 -d' ')" "$(echo "$current_setting" | cut -f3 -d' ')" "$(echo "$current_setting" | cut -f4 -d' ')

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
