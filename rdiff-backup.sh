#!/bin/zsh
# -x for debug
# http://rdiff-backup.nongnu.org/examples.html

dest="/mnt/styx/raid/backups"
backup=("/home" "/etc" "/var" "/srv" "/boot" "/usr/local")
remove_older_than="6W"
conf="/usr/local/etc/rdiff"


[[ ! -d "$dest" ]] && echo "$dest doesn't exist.. exit" && exit 1;

error=0;

for bck in $backup; do
    bckfile=${${bck//\//_}#_}; # replace / with _ and remove first _
    conffile="${conf}/${bckfile}.conf";

    if [[ -f "$conffile" ]]; then
        echo "> backup $bck using $conffile"
        rdiff-backup --exclude-sockets --exclude-fifos --include-globbing-filelist "$conffile" "$bck" "$dest/$bckfile"
    else
        echo "> backup $bck"
        rdiff-backup --exclude-sockets --exclude-fifos "$bck" "$dest/$bckfile"
    fi
    ret=$?
    [[ $error == 0 ]] && error=$ret

    echo ">> cleanup.."
    rdiff-backup --remove-older-than "$remove_older_than" "$dest/$bckfile";

    echo;
done;

echo "everythings done.. exit"
exit $error;
