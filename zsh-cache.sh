#!/bin/zsh
prefix="[zsh-cache]"
echo -n "$prefix refresh..."

# change dir
cd $XDG_CACHE_HOME/zsh/complete

# delete old stuff
rm *

# all pkgs
pacman -Ssq >pac{in,rep{,s}}

# installed pks
pacman -Qq >pac{rm,loc{,s},tree,list}

# man pages
apropos . --long | awk '{print $1}' >man

# ssh hosts
grep "^Host " $HOME/.ssh/config | awk '{print $2}' >{ssh,scp}

# end
echo -e "\r$prefix refresh done"
return 0
