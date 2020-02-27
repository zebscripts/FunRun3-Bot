#!/system/bin/sh

# Variables
DEVICEWIDTH=1920
SCREENSHOTLOCATION="/storage/emulated/0/scripts/afk-arena/screen.dump"
STATE="unknown"
RGB=000000
# Arrays
ARRAYRGB=()
ARRAYRGB2=()
# Counts
SCREENCOUNT=0
RGBCOUNT=0
INGAMECOUNT=0
# Parameters
PARAMX=1
PARAMY=2
# Coordinates
PIXELX=0
PIXELY=0
# Return values
OUTPUT=1

# Default wait time for actions
function wait() {
    sleep 0.3
}

# Resets variables
function resetVariables() {
    RGBCOUNT=0
    PARAMX=1
    PARAMY=2
    OUTPUT=1
}

# Takes a screenshot and saves it
function takeScreenshot() {
    screencap $SCREENSHOTLOCATION
    SCREENCOUNT=$((SCREENCOUNT + 1))
    echo "Screenshot #$SCREENCOUNT taken!"
}

# Switches between last app
function switchApp() {
    input keyevent KEYCODE_APP_SWITCH
    input keyevent KEYCODE_APP_SWITCH
    echo "Switched apps"
}

# Gets pixel color
function readRGB() {
    ARRAYRGB=()
    ARGS=("$@")
    #echo "ARGS: ${ARGS[*]}"

    while [ $RGBCOUNT -lt $1 ]; do
        #echo "The counter is $RGBCOUNT"
        PIXELX=${ARGS[$PARAMX]}
        PIXELY=${ARGS[$PARAMY]}
        #echo "X: $PIXELX"
        #echo "Y: $PIXELY"

        # RGB
        let offset=$DEVICEWIDTH*$PIXELY+$PIXELX+3
        #echo $offset
        RGB=$(dd if=$SCREENSHOTLOCATION bs=4 skip="$offset" count=1 2>/dev/null | hd)
        RGB=${RGB:9:9}
        RGB="${RGB// /}"
        #echo "RGB $RGBCOUNT: '$RGB'"

        # Add RGB to array
        ARRAYRGB[$RGBCOUNT]=$RGB

        # Increment variables
        let RGBCOUNT=RGBCOUNT+1
        let PARAMX=PARAMX+2
        let PARAMY=PARAMY+2
        #echo "RGBCOUNT: $RGBCOUNT"
        #echo "PARAMX: $PARAMX"
        #echo "PARAMY: $PARAMY"
    done
    echo "ARRAYRGB: ${ARRAYRGB[*]}"
    resetVariables
}

# Gets pixel color for AI
function readRGB2() {
    PARAMX=2
    PARAMY=3
    ARGS=("$@")
    #echo "ARGS: ${ARGS[*]}"

    if [ "$2" = 2 ]; then
        let RGBCOUNT=RGBCOUNT-5
    fi
    while [ $RGBCOUNT -lt $1 ]; do
        #echo "The counter is $RGBCOUNT"
        PIXELX=${ARGS[$PARAMX]}
        PIXELY=${ARGS[$PARAMY]}
        #echo "X: $PIXELX"
        #echo "Y: $PIXELY"

        # RGB
        let offset=$DEVICEWIDTH*$PIXELY+$PIXELX+3
        #echo $offset
        RGB=$(dd if='/sdcard/Script-Images/screen.dump' bs=4 skip="$offset" count=1 2>/dev/null | hd)
        RGB=${RGB:9:9}
        RGB="${RGB// /}"

        if [ "$2" = 2 ]; then
            let RGBCOUNT=RGBCOUNT+5
        fi
        # Add RGB to array
        ARRAYRGB2[$RGBCOUNT]=$RGB
        if [ "$2" = 2 ]; then
            let RGBCOUNT=RGBCOUNT-5
        fi

        # Increment variables
        let RGBCOUNT=RGBCOUNT+1
        let PARAMX=PARAMX+2
        let PARAMY=PARAMY+2
        #echo "RGBCOUNT: $RGBCOUNT"
        #echo "PARAMX: $PARAMX"
        #echo "PARAMY: $PARAMY"
    done

    echo "ARRAYRGB2: ${ARRAYRGB2[*]}"

    # Reset variables
    PARAMX=2
    PARAMY=3
    if [ "$2" = "2" ]; then
        RGBCOUNT=0
        PARAMX=1
        PARAMY=2
    fi
}

# Checks where the player is in the game
function checkRGBstate() {
    # Lobby
    if [ "${#ARRAYRGB[@]}" = "3" ]; then
        if [ "${ARRAYRGB[0]}" = "fff9ef" ] && [ "${ARRAYRGB[1]}" = "fff9ef" ] && [ "${ARRAYRGB[2]}" = "c45129" ]; then
            STATE="lobby"
        else
            STATE="unknown"
            OUTPUT=0
        fi
    # loading, logo
    elif [ "${#ARRAYRGB[@]}" = "2" ]; then
        if [ "${ARRAYRGB[0]}" = "19ef27" ] && [ "${ARRAYRGB[1]}" = "f3d19e" ]; then
            STATE="loading"
        elif [ "${ARRAYRGB[0]}" = "dedbde" ] && [ "${ARRAYRGB[1]}" = "f79218" ]; then
            STATE="logo"
        else
            STATE="unknown"
            OUTPUT=0
        fi
    else
        echo "Error: ARRAYRGB length is invalid."
        ARRAYRGB=()
        STATE="unknown"
    fi
    echo "Updated STATE to '$STATE'"
}

# Checks where in the lobby the player is
function checkRGBlobby() {
    if [ "${ARRAYRGB[0]}" = "442211" ]; then
        STATE="lobby:leaderboard"
    elif [ "${ARRAYRGB[1]}" = "442211" ]; then
        STATE="lobby:clan"
    elif [ "${ARRAYRGB[2]}" = "442211" ]; then
        STATE="lobby:home"
    elif [ "${ARRAYRGB[3]}" = "442211" ]; then
        STATE="lobby:shop"
    elif [ "${ARRAYRGB[4]}" = "442211" ]; then
        STATE="lobby:vault"
    else
        STATE="unknown"
    fi
    echo "Updated STATE to '$STATE'"
}

# Checks where ingame the player is
function checkRGBingame() {
    # podium
    if [ "${#ARRAYRGB[@]}" = "3" ]; then
        if [ "${ARRAYRGB[0]}" = "fffeff" ] && [ "${ARRAYRGB[1]}" = "fffdff" ] && [ "${ARRAYRGB[2]}" = "fff9ff" ]; then
            STATE="ingame:podium"
        elif [ "$STATE" = "ingame:podium" ]; then
            STATE="ingame:end"
        else
            STATE="unknown"
            OUTPUT=0
        fi
    # SFP, voting, countdown, start, running, finish
    elif [ "${#ARRAYRGB[@]}" = "2" ]; then
        if [ "${ARRAYRGB[0]}" = "93d6ff" ] && [ "${ARRAYRGB[1]}" = "2b9438" ]; then
            STATE="ingame:sfp"
        elif [ "${ARRAYRGB[0]}" = "c45129" ] && [ "${ARRAYRGB[1]}" = "c45129" ]; then
            STATE="ingame:voting"
        elif [ "${ARRAYRGB[0]}" = "ffffff" ] && [ "${ARRAYRGB[1]}" = "ffffff" ]; then
            STATE="ingame:start"
        elif [ "${ARRAYRGB[0]}" = "ffffff" ] && [ "${ARRAYRGB[1]}" = "e7d1c7" ]; then
            STATE="ingame:countdown"
        elif [ "${ARRAYRGB[0]}" = "e7d1c7" ] && [ "${ARRAYRGB[1]}" = "e7d1c7" ]; then
            STATE="ingame:running"
            OUTPUT=1
        elif [ "$STATE" = "ingame:running" ] && [ "${ARRAYRGB[0]}" != "e7d1c7" ] && [ "${ARRAYRGB[1]}" != "e7d1c7" ]; then
            STATE="ingame:finish"
        else
            STATE="unknown"
            OUTPUT=0
        fi
    else
        echo "Error: ARRAYRGB length is invalid."
        STATE="unknown"
    fi
    echo "Updated STATE to '$STATE'"
}

# Ingame: Jump
function actionUp() {
    input tap 1760 950
    echo "Action: Up"
}

# Ingame: Dodge
function actionDown() {
    input tap 1500 950
    echo "Action: Down"
}

# Ingame: Powerup
function actionPowerup() {
    input tap 130 950
    echo "Action: Powerup"
}

# Lobby: Play button
function actionPlay() {
    input tap 1550 706
    echo "Action: Play"
}

# Lobby: Play Menu
function actionPlayMenu() {
    input tap 1470 780
    echo "Action: PlayMenu"
}

# Lobby: Play Menu: Custom game
function actionPlayMenuCustom() {
    input tap 1315 682
    echo "Action: PlayMenuCustom"
}

# Lobby: Play Menu: Back Arrow
function actionPlayMenuArrow() {
    input tap 1177 682
    echo "Action: PlayMenuArrow"
}

# Creates a custom game on a random map
function createCustomGame() {
    if [ "$STATE" = "lobby:home" ]; then
        wait
        actionPlayMenu
        wait
        actionPlayMenuCustom
        wait
        actionPlayMenuArrow
        wait
        actionPlay
        STATE="unknown"
        loopIngame
    else
        echo "Cant create Custom game, User isnt in lobby:home!"
    fi
}

# Launch the AI
function startAi() {
    echo "-- -- -- Launching AI -- -- --"
    until [ "$STATE" = "ingame:podium" ]; do
        resetVariables
        takeScreenshot
        tryIngameRunning
        if [ "$OUTPUT" = 1 ]; then
            aiTryObstacles
        elif [ "$OUTPUT" = 0 ]; then
            resetVariables
            tryIngamePodium
            if [ "$OUTPUT" = 0 ]; then
                let INGAMECOUNT=INGAMECOUNT+1
                if [ "$INGAMECOUNT" = 30 ]; then
                    # Exit function
                    return 1
                fi
            fi
        fi
    done
}

function aiTryObstacles() {
    echo "Searching for obstacles..."
    readRGB2 5 1 900 550 900 600 900 650 900 750 900 900
    sleep 0.5
    takeScreenshot
    readRGB2 5 2 900 550 900 600 900 650 900 750 900 900
    aiCheckPlayerStopped
}

function aiCheckPlayerStopped() {
    if [ "${ARRAYRGB2[0]}" = "${ARRAYRGB2[5]}" ] && [ "${ARRAYRGB2[1]}" = "${ARRAYRGB2[6]}" ] && [ "${ARRAYRGB2[4]}" = "${ARRAYRGB2[9]}" ]; then
        echo fodasse!
        actionUp
        actionUp
        actionUp
    elif [ "${ARRAYRGB2[1]}" = "${ARRAYRGB2[6]}" ] && [ "${ARRAYRGB2[2]}" = "${ARRAYRGB2[7]}" ]; then
        actionDown
    elif [ "${ARRAYRGB2[2]}" = "${ARRAYRGB2[7]}" ]; then
        actionUp
    elif [ "${ARRAYRGB2[3]}" = "${ARRAYRGB2[8]}" ]; then
        actionUp
    fi
}

# Tries to find the logo
function tryLogo() {
    echo "Searching for logo"
    readRGB 2 700 435 860 440
    checkRGBstate
}

# Tries to find the loading screen
function tryLoading() {
    echo "Searching for loading"
    readRGB 2 540 1025 500 1025
    checkRGBstate
}

# Tries to find the lobby
function tryLobby() {
    echo "Searching for lobby"
    readRGB 3 54 511 50 695 180 985
    checkRGBstate
}

# Until loop to set the STATE
function loopState() {
    until [ "$STATE" = "null" ]; do
        echo "STATE: $STATE"
        case "$STATE" in
        unknown)
            takeScreenshot
            tryLogo
            if [ "$OUTPUT" = "0" ]; then
                resetVariables
                tryLoading
                if [ "$OUTPUT" = "0" ]; then
                    resetVariables
                    tryLobby
                    if [ "$OUTPUT" = "0" ]; then
                        resetVariables
                        echo "I have no fucking clue where you are"
                    fi
                fi
            fi
            ;;
        logo)
            takeScreenshot
            tryLogo
            ;;
        loading)
            takeScreenshot
            tryLoading
            ;;
        lobby*)
            takeScreenshot
            readRGB 5 640 1050 835 1050 1045 1050 1245 1050 1450 1050
            checkRGBlobby
            createCustomGame
            ;;
        *)
            echo "Rip on the STATE switch case"
            ;;
        esac
    done
}

# Tries to find ingame: searching for players
function tryIngameSFP() {
    echo "Searching for ingame:sfp"
    readRGB 2 930 200 970 895
    checkRGBingame
}

# Tries to find ingame: voting
function tryIngameVoting() {
    echo "Searching for ingame:voting"
    readRGB 2 1600 800 1700 800
    checkRGBingame
}

# Tries to find ingame: countdown
function tryIngameCountdown() {
    echo "Searching for ingame:countdown"
    readRGB 2 992 372 1505 970
    checkRGBingame
}

# Tries to find ingame: go!
function tryIngameStart() {
    echo "Searching for ingame:start"
    readRGB 2 1114 338 810 378
    checkRGBingame
}

# Tries to find ingame: running
function tryIngameRunning() {
    echo "Searching for ingame:running"
    readRGB 2 1505 970 1770 970
    checkRGBingame
}

# Tries to find ingame: podium
function tryIngamePodium() {
    echo "Searching for ingame:podium"
    readRGB 3 580 720 280 720 845 720
    checkRGBingame
}

# Until loop to set the STATE while ingame
function loopIngame() {
    until [ "$STATE" = "lobby" ]; do
        echo "STATE: $STATE"
        case "$STATE" in
        unknown)
            echo "Searching for ingame:sfp"
            takeScreenshot
            tryIngameSFP
            if [ "$OUTPUT" = "0" ]; then
                resetVariables
                tryIngameVoting
                if [ "$OUTPUT" = "0" ]; then
                    resetVariables
                    tryIngameCountdown
                    if [ "$OUTPUT" = "0" ]; then
                        resetVariables
                        tryIngameStart
                        if [ "$OUTPUT" = "0" ]; then
                            resetVariables
                            echo "I have no fucking clue where you are"
                            let INGAMECOUNT=INGAMECOUNT+1
                            if [ "$INGAMECOUNT" = 30 ]; then
                                INGAMECOUNT=0
                                echo "-- -- -- Bringing you back to lobby -- -- --"
                                break
                            fi
                        fi
                    fi
                fi
            fi
            ;;
        "ingame:sfp")
            takeScreenshot
            tryIngameSFP
            ;;
        "ingame:voting")
            takeScreenshot
            tryIngameVoting
            ;;
        "ingame:countdown")
            takeScreenshot
            tryIngameCountdown
            ;;
        "ingame:start")
            startAi
            if [ "$INGAMECOUNT" = 30 ]; then
                echo "-- -- -- Bringing you back to lobby -- -- --"
                break
            fi
            ;;
        "ingame:podium")
            takeScreenshot
            tryIngamePodium
            ;;
        "ingame:end")
            STATE="unknown"
            INGAMECOUNT=0
            break
            ;;
        *)
            echo "Rip on the loopIngame switch case"
            ;;
        esac
    done
}

# Execute code after loading functions
am force-stop com.dirtybit.fra
#input keyevent 3
#input tap 940 775

monkey -p com.dirtybit.fra -c android.intent.category.LAUNCHER 1

loopState

echo "Script end"
exit
#switch
