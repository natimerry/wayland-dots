function list_geometry () {
	[ "$2" = with_description ] && local append="\t\(.title)" || local append=
    if [ "$1" = focused ]; then
        hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])'$append'"'
    else
        hyprctl -j clients | jq -r '.[] | select(.workspace.id | contains('$(hyprctl -j monitors | jq -r 'map(.activeWorkspace.id) | join(",")')')) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])'$append'"'
    fi
}

WINDOWS=`list_geometry visible with_description`
FOCUSED=`list_geometry focused`

CHOICE=`tofi --prompt-text 'Screenshot' << EOF
fullscreen
region
focused
$WINDOWS
EOF`
SAVEDIR=${HYPRLAND_INTERACTIVE_SCREENSHOT_SAVEDIR}
[ -z "$SAVEDIR" ] && SAVEDIR=${SWAY_INTERACTIVE_SCREENSHOT_SAVEDIR:=~/pictures/screenshots}
mkdir -p -- "$SAVEDIR"
FILENAME="$SAVEDIR/$(date +'%Y-%m-%d-%H%M%S_screenshot.png')"
EXPENDED_FILENAME="${FILENAME/#\~/$HOME}"
case $CHOICE in
    fullscreen)
        sleep 0.5
        grim "$EXPENDED_FILENAME"
	;;
    region)
        grim -g "$(slurp)" "$EXPENDED_FILENAME"
	;;
    focused)
        sleep 0.5
        grim -g "$FOCUSED" "$EXPENDED_FILENAME"
	;;
    '')
        notify-send "Screenshot" "Cancelled"
        exit 0
        ;;
    *)
        sleep 0.5
    	GEOMETRY="`echo \"$CHOICE\" | cut -d$'\t' -f1`"
        grim -g "$GEOMETRY" "$EXPENDED_FILENAME"
esac
# If swappy is installed, prompt the user to edit the captured screenshot
if command -v swappy $>/dev/null
then
    EDIT_CHOICE=`tofi --prompt-text 'Edit' << EOF
yes
no
EOF`
    case $EDIT_CHOICE in
        yes)
            swappy -f "$EXPENDED_FILENAME" -o "$EXPENDED_FILENAME"
            ;;
        no)
            ;;
        '')
            ;;
    esac
fi
wl-copy < "$EXPENDED_FILENAME"
notify-send "Screenshot" "File saved as <i>'$FILENAME'</i> and copied to the clipboard." -i "$EXPENDED_FILENAME"
