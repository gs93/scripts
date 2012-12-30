#!/bin/bash
case $1 in
    # audiostuff (play, next, prev, stop, list) {{{1
    audioplay)
        ncmpcpp toggle;;
    audionext)
        ncmpcpp next
        killall -USR1 dwmstatus
        ;;
    audioprev)
        ncmpcpp prev
        killall -USR1 dwmstatus
        ;;
    audiostop)
        killall dwmstatus
        dwmstatus &
        ;;
    audiolist)
        nl=$(zenity --list --text="Choose playlist" --column="" --hide-header `mpc lsplaylists`)
        if [ $nl ]; then
            mpc -q clear && mpc -q load "$nl";
        else
            echo "aborted.";
        fi
        ;;
    # 1}}}
    lock) # {{{1
        set -o monitor # for job control
        # locking {{{2
        xset dpms force off & # turn off screen
        slock & # lock screen
        # pause mpd play and save status
        if [ "$(mpc status | head -2 | tail -1 | awk '{print $1}')" = "[playing]" ]; then # [playing]
            mpc -q pause # pause music
            mpdplaying=true
        fi
        xset s 5 5 # turn off screen after 5s inactivity

        # change pidgin status
        stat=$(purple-remote getstatus);
        if [ "$stat" !=  "offline" ] && [ "$stat" != "invisible" ]; then
            purple-remote setstatus?status=unavailable
        fi
        # 2}}}
        fg >/dev/null 2>&1 # wait for the end of slock
        # unlocking {{{2
        xset s 0 0 # turn screen never off
        # restore mpd status
        if [ $mpdplaying ]; then
            mpc -q play
        fi
        purple-remote setstatus?status=$stat #&message=$msg # restore pidgin status
        # 2}}}
        ;; # 1}}}
    # volume (raise, lower, mute) {{{1
    raisevolume)
        amixer set Master 2.5%+ unmute >/dev/null;;
    lowervolume)
        amixer set Master 2.5%- unmute >/dev/null;;
    audiomute)
        amixer set Master toggle >/dev/null;;
    # }}}1
    # apps {{{1
    terminal)
        urxvtc &;;
    browser)
        $BROWSER &;;
    mail)
        claws-mail &;;
    calculator)
        galculator &;;
    screenshot)
        scrot "%Y-%m-%d-%H%M%S_\$wx\$h.png" -e "mv \$f $HOME/pictures/screens/";;
    screenshot-selection)
        scrot -s "%Y-%m-%d-%H%M%S_selection_\$wx\$h.png" -e "mv \$f $HOME/pictures/screens/";;
    # 1}}}
    autostart) # {{{1
        pulseaudio --start
        (urxvtd -f && urxvtc) &
        mpd &
        (sleep 5s && dropboxd) &
        #pidgin --nologin &
        claws-mail &
        xset s 0 0 &
        encfs "$HOME/documents/Dropbox/bla" "$HOME/documents/box" --extpass="$HOME/.pw-dropbox"
        nm-applet &
        ;; # 1}}}
    shutdown) # {{{1
        (mpc -q seek 0 ; mpc -q pause)
        killall pidgin dropbox skype
        claws-mail --exit
        sync
        systemctl poweroff
        ;; # 1}}}
    *) # {{{1
        notify-send --urgency=critical --expire-time=0 "commands.sh" "unknown command: \"$1\""
        ;; # 1}}}
esac
