#!/bin/sh

battery_percent()
{
    ioreg -c AppleSmartBattery -w0 | \
        grep -o '"[^"]*" = [^ ]*' | \
        sed -e 's/= //g' -e 's/"//g' | \
        sort | \
        while read key value; do
        case $key in
            "MaxCapacity")
                export maxcap=$value;;
            "CurrentCapacity")
                export curcap=$value;;
        esac
        if [[ -n "$maxcap" && -n $curcap ]]; then
            percent=$(( 100 * $curcap / $maxcap ))
            echo "$percent"
            break
        fi
    done
}

# gives a colour to be fed to tmux set -g status-left
# this then shows the battery percentage in green if its good,
# yellow ok and red if nearly flat
case $1 in
    colour)
        if (( `battery_percent` < 10 ))
        then
            echo "#[fg=red]"
        elif (( `battery_percent` < 40 ))
        then
            echo "#[fg=yellow]"
        else
            echo "#[fg=green]"
        fi
        exit ;;
esac

BATTERY_STATUS=`battery_percent`
echo ${BATTERY_STATUS}%
