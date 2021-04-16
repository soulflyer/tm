#!/bin/bash
[[ -f /opt/local/bin/tmux ]] && TMUX_EXECUTABLE="/opt/local/bin/tmux" || TMUX_EXECUTABLE=`which tmux`
echo "tmux executeable found in " $TMUX_EXECUTABLE
SESSION="dev"
PATHNAME=`pwd`

RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOUR="\033[0m"

while getopts "ns:?h" flag
do
    echo "$flag" $OPTIND $OPTARG
    case $flag in
        "?" | "h" )
        cat <<EOF
tm -n
    creates a new .tmux in the current directory and runs tmux

tm -s session
    attatches the new window to the named session rather than the default (dev)

tm
    starts or attaches to tmux using the .tmux file (if present) to create a new
    window

tm ?  (or h or help)
    this message
EOF
        ;;
        "n" )
        # Create new .tmux file
            if [ ~/.tmux.default ]
            then
                cp ~/.tmux.default ./.tmux
            else
                cat <<EOF > ./.tmux
#!/bin/bash
#
# this file was created by tm new
#
# Contains commands to add a new window to an existing tmux session
#
# Note that it is best to create the window in detached state (-d option) so that
# the window is complete before displaying it with select-window. tmux messes up the
# initial display if you don't.

# *************************************************************************************
# Build your window here
# *************************************************************************************
tmux split-window -d -h -t :\$LABEL
tmux split-window -d -v -t :\$LABEL 'emacsclient -nw . ; bash -l'
# Set the layout by hand then call tmux list-windows to get the incantation for select-layout
tmux select-layout -t :\$LABEL "5c65,204x63,0,0{111x63,0,0,92x63,112,0[92x43,112,0,92x19,112,44]}"
tmux select-window -t :\$LABEL
# *************************************************************************************
EOF
                chmod a+x ./.tmux
            fi
            echo "create new .tmux"
        ;;
        "s" )
            SESSION=$OPTARG
        ;;

    esac
done
shift $((OPTIND-1))
echo "$*"
echo "Session $SESSION"
if [ "$*" ]
then
    PATHNAME=$*
fi
echo "pathname $PATHNAME"
cd $PATHNAME
PATHNAME=$(pwd)

LABEL=$(basename $PATHNAME)
LABEL=${LABEL//./_}
echo "Label $LABEL"

export LABEL PATHNAME

# If there isn't already a tmux session running then start one with a default window
# and a window on the current  (or specified) directory. If it is started from the
# home directory then only the default window will be created
if ! $TMUX_EXECUTABLE list-sessions
then
    cd ~
    echo "No session, creating a new one"
    $TMUX_EXECUTABLE start-server
    $TMUX_EXECUTABLE new-session -d -s dev
    $TMUX_EXECUTABLE rename-window `basename $HOME`
    if [ -e ~/.tmux/startup ]
    then
        bash ~/.tmux/startup
    else
        $TMUX_EXECUTABLE split-window -h
        $TMUX_EXECUTABLE split-window -v
    fi
else
    echo "found session"
# fi
    echo $TMUX_EXECUTABLE
    # Don't know why, but this doesn't terminate. tmux inside $() or `` doesn't seem to work
    # WINDOW=`$TMUX_EXECUTABLE list-windows | awk '{ print $2}' | grep ^$LABEL.$`
    $TMUX_EXECUTABLE list-windows > "/tmp/tmux-windows"
    WINDOWNAMES=$(cat "/tmp/tmux-windows" | awk '{print $2}')
    echo "Window names:"
    echo $WINDOWNAMES
    echo "******************"
    WINDOW=$(cat "/tmp/tmux-windows" | awk '{print $2}' | grep ^$LABEL.$)
    echo "WINDOW: $WINDOW"
    if [[ -z $WINDOW ]]
    then
    #    $TMUX_EXECUTABLE set default-path "$PATHNAME"
        $TMUX_EXECUTABLE new-window -d -n "$LABEL"
        if [ -f "$PATHNAME/.tmux" ]
        then
            echo "Found tmux conf file"
            echo "Adding window to session by running $PATHNAME/.tmux"
            bash "$PATHNAME/.tmux"
            echo "Attaching to session"
        else
            echo "No project .tmux found"
            if [ -e ~/.tmux.default ]
            then
                echo "Adding window to session by running ~/.tmux.default"
                bash ~/.tmux.default
            fi
        fi
    else
        echo -e "${RED}Warning:${NOCOLOUR} window called $WINDOW already exists"
    fi
fi
$TMUX_EXECUTABLE -2 attach
