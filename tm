#!/bin/bash

if [ "$1" = "?" ] || [ "$1" = help ] || [ "$1" = h ]
then
    cat <<EOF

tm new session
    creates a new .tmux in the current directory and runs tmux

tm new (or n)
    creates a new .tmux in the current directory and runs tmux with the default session name (dev)

tm
    starts or attaches to tmux using the .tmux file (if present) to create a new window

tm ?  (or h or help)
    this message
EOF
else
    PATHNAME=`pwd`
    LABEL=`basename $PATHNAME`

    SESSION="dev"

    if [ $2 ]
    then
        SESSION=$2
    fi

    if [ -e ./.tmux ]
    then
        echo "Found tmux conf file"
        if ! tmux has-session -t $SESSION
        then
            echo "creating new empty session"
            tmux new-session -d -s $SESSION
        fi
        echo "Adding window to session by running $PATHNAME/.tmux"
        bash ./.tmux
        echo "Attaching to session"
        tmux attach
    else
        echo "No project .tmux found"
        if [ "$1" = "n" ] || [ "$1" = "new" ]
        then
            echo "Create new .tmux"
            cat <<EOF > ./.tmux
#!/bin/bash
#
# Contains commands to add a new window to an existing tmux session
#
# Note that it is best to create the window in detached state (-d option) so that
# the window is complete before displaying it with select-window. tmux messes up the
# initial display if you don't.

# Set the window name to the last part of the directory path, removing any . in the
# directory name so tmux doesn't confuse it with a pane separator.
PATHNAME=\`pwd\`
LABEL=\`basename \$PATHNAME | tr -d '.' \`

# Check if the window already exists, but don't stay on it so we can see the warning
# message.
tmux select-window -t \$LABEL
WINDOW_EXISTS=\$?

tmux select-window -n

if [ \$WINDOW_EXISTS = 1 ]
then

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

else
    echo "Warning: window called \$LABEL already exists"
fi
EOF
            chmod a+x ./.tmux
            exec ./.tmux
        fi
        if ! tmux has-session -t $SESSION
        then
            echo "creating new development session"
            exec mux $SESSION
        else
            echo "Attaching to existing session"
            tmux attach -t $SESSION
        fi
    fi
fi
