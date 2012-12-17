#!/bin/bash


SESSION="dev"
PATHNAME=`pwd`


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
            echo "Create new .tmux"
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
    tmux set default-path \$PATHNAME
    tmux new-window -d -n \$LABEL
    tmux split-window -d -h -t \$LABEL
    tmux split-window -d -v -t \$LABEL 'emacsclient -nw . ; bash -l'
# Set the layout by hand then call tmux list-windows to get the incantation for select-layout
    tmux select-layout -t \$LABEL "5c65,204x63,0,0{111x63,0,0,92x63,112,0[92x43,112,0,92x19,112,44]}"
    tmux select-window -t \$LABEL
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
echo $*
echo "Session $SESSION"
if [ $* ]
then
    PATHNAME=$*
fi
echo "pathname $PATHNAME"
LABEL=`basename $PATHNAME`
echo "Label $LABEL"

export LABEL PATHNAME

WINDOW=`tmux list-windows | awk '{ print $2 }' | grep ^$LABEL$`
echo "WINDOW: $WINDOW"
if [[ -z $WINDOW ]]
then
    if ! tmux has-session -t $SESSION
    then
        echo "creating new empty session"
        tmux new-session -d -s $SESSION
    fi

    if [ -e $PATHNAME/.tmux ]
    then
        echo "Found tmux conf file"
        if ! tmux has-session -t $SESSION
        then
            echo "creating new empty session"
            tmux new-session -d -s $SESSION
        fi
        echo "Adding window to session by running $PATHNAME/.tmux"
        bash $PATHNAME/.tmux
        echo "Attaching to session"
    else
        echo "No project .tmux found"
        if [ -e ~/.tmux.default ]
        then
            echo "Adding window to session by running ~/.tmux.default"
            bash ~/.tmux.default
        else
            tmux new-window -n $LABEL
        fi
    fi
    echo "attaching"
    tmux attach
else
    echo "Warning: window called $WINDOW already exists"
fi
