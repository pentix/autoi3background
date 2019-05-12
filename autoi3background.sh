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
    printf "\033[1mUSAGE:\033[0m $0 [OPTIONS] \033[4mpath/to/wallpaper.png\033[0m\n\n"
    printf "\033[1mOPTIONS:\033[0m\n\t"
    printf -- "-h  | --help      Print possible program flags and parameters\n\t"
    printf -- "-i  | --invert    Invert the calculated colors (matches better for some themes)\n\n"
    
}

# Check for arguments
if (( $# < 1 ))
then
    error "Too few arguments"
    usage
    exit 1
fi

# argument defaults
help=0
invert=0
wallpaper=""

# Parse arguments
for arg in $@
do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]
    then
	help=1
	continue
    fi

    if [[ "$arg" == "-i" || "$arg" == "--invert" ]]
    then
	invert=1
	continue
    fi
    
    # else assume this is the wallpaper
    wallpaper="$arg"
done

if [[ "$wallpaper" == "" ]]
then
    error "You need to specify the wallpaper!"
    exit 1
fi

# ---- End of argument parsing ----



if [[ $help == 1 ]]
then
    usage
    exit 0
fi

# Check if provided wallpaper exists
test -e "$wallpaper"
if [[ $? != 0 ]]
then
    error "File '$wallpaper' does not exist"
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
c=$(convert "$wallpaper" -resize 1x1\! -format "%[fx:int(255*r+.5)],%[fx:int(255*g+.5)],%[fx:int(255*b+.5)]" info:-)
r=$(echo $c | cut -f1 -d,)
g=$(echo $c | cut -f2 -d,)
b=$(echo $c | cut -f3 -d,)

# value between 0 and 255
luminance=$(bc <<< "0.299*$r + 0.587*$g + 0.114*$b")

#if inv arg is on, invert the title colors
if [[ $invert == 1 ]]
then
    # invert background
    r=$(bc <<< "255 - $r")
    g=$(bc <<< "255 - $g")
    b=$(bc <<< "255 - $b")

    # if contrasts shouldn't be too big, 
    # after inverting colors, change luminance by a changing bg_factor appropriately
    if (( $(echo "$luminance > 127.5"|bc -l) )); then
	    # background is bright
	    bg_factor="1.1"	
    else
	    # background is dark
	    bg_factor="0.9"
    fi

    # update colors
    r=$(bc <<< "($r*$bg_factor)")
    g=$(bc <<< "($g*$bg_factor)")
    b=$(bc <<< "($b*$bg_factor)")

    # round to integer
    r=$(bc <<< " ( $r + 0.5 )/1")
    g=$(bc <<< " ( $g + 0.5 )/1")
    b=$(bc <<< " ( $b + 0.5 )/1")
fi


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
focused_average=$(printf "#%02x%02x%02x\n" $r $g $b)
unfocused_average=$(printf "#%02x%02x%02x\n" $(($r*3/4)) $(($g*3/4)) $(($b*3/4)))
text_average=$(printf "#%02x%02x%02x\n" $tc_r $tc_g $tc_b)

# focused settings
focused_new_conf_line_str="client.focused $focused_average $focused_average $text_average"
focused_current_setting=$(grep -P "^client.focused " ~/.config/i3/config)
focused_conf_line_str="client.focused "$(echo "$focused_current_setting" | cut -f2 -d' ')" "$(echo "$focused_current_setting" | cut -f3 -d' ')" "$(echo "$focused_current_setting" | cut -f4 -d' ')

# unfocused settings
unfocused_new_conf_line_str="client.unfocused $unfocused_average $unfocused_average $text_average"
unfocused_current_setting=$(grep -P "^client.unfocused " ~/.config/i3/config)
unfocused_conf_line_str="client.unfocused "$(echo "$unfocused_current_setting" | cut -f2 -d' ')" "$(echo "$unfocused_current_setting" | cut -f3 -d' ')" "$(echo "$unfocused_current_setting" | cut -f4 -d' ')


echo "Current settings:         $focused_conf_line_str"
echo "                          $unfocused_conf_line_str"
echo ""
echo "Suggested new settings:   $focused_new_conf_line_str"
echo "                          $unfocused_new_conf_line_str"
echo ""

printf "Do you want to proceed? [y|n]  "
read y

if [[ "$y" == "y" ]]
then
    cp ~/.config/i3/config{,_before_autoi3background.bak}
    sed -i "s|$focused_conf_line_str|$focused_new_conf_line_str|g" ~/.config/i3/config
    sed -i "s|$unfocused_conf_line_str|$unfocused_new_conf_line_str|g" ~/.config/i3/config
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
