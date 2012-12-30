#!/bin/zsh
prefix="[zsh-cache]"
echo -n "$prefix refresh..."

# change dir
cd $HOME/.cache/zsh/complete

# delete old stuff
rm pac{in,rep{,s},rm,loc{,s},list}

# all pkgs
pacman -Ssq >pac{in,rep{,s}}

# installed pks
pacman -Qq >pac{rm,loc{,s},list}

# end
echo -e "\r$prefix refresh done"
return 0
