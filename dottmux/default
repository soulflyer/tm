#!/bin/bash
#
# This file was copied from ~/.tmux.default
#
# Contains commands to add a new window to an existing tmux session
#
# Note that it is best to create the window in detached state (-d option) so that
# the window is complete before displaying it with select-window. tmux messes up the
# initial display if you don't.

# *************************************************************************************
# Build your window here
# *************************************************************************************
tmux set default-path $PATHNAME
tmux new-window -d -n $LABEL
tmux split-window -d -h -t $LABEL
tmux split-window -d -v -t $LABEL 'emacsclient -nw . ; bash -l'
t the layout by hand then call tmux list-windows to get the incantation for select-layout
tmux select-layout -t $LABEL "5c65,204x63,0,0{111x63,0,0,92x63,112,0[92x43,112,0,92x19,112,44]}"
tmux select-window -t $LABEL
# Put the cursor in pane 2 (the top right pane, running emacs client)
tmux select-pane -t 2
# *************************************************************************************
