#!/usr/bin/perl
# Name        : sync-clip+
# Version     : 0.1b
# URL         : none
# Licenses    : GPL
# Depends on  : perl
# Date        : Wed Sep 19 22:46:14 CEST 2012
# Updated     : Thu Sep 20 00:59:12 CEST 2012
# Description : ---

use strict;
use warnings;

use File::Basename;

# TODO: get this, "music_directory" and "playlist_directory" (.mpd/mpd.conf)
my $musicHome = $ENV{HOME} . "/music";
my $playlistFolder = $ENV{HOME} . "/.mpd/playlists";
my $targetFolder = "/run/media/gl/5495-A68E/MUSIC";

sub parsePlaylist { # {{{1
    my @files;
    open PLAYLIST, "$_[0]" or die "Can't open $_[0]: $!\n";
    while (<PLAYLIST>) {
        chomp;                  # no newline
        s/#.*//;                # no comments
        s/^\s+//;               # no leading white
        s/\s+$//;               # no trailing white
        next unless length;     # anything left?
        push(@files, $_);
    }   
    close(PLAYLIST);
    @files; # return
} # 1}}}

sub getPlaylists { # {{{1
    opendir(D, "$_[0]") or die "Can't opendir $_[0]: $!\n";
    my @playlists = readdir(D);
    closedir(D);
    @playlists; # return
} # 1}}}

sub main { # {{{1
    foreach (getPlaylists($playlistFolder)) {
        next unless ($_ =~ m/\.m3u$/);
        print "sync $_\n";

        open M3U, ">$targetFolder/$_";
        my @files = parsePlaylist("$playlistFolder/$_");

        # playlists start with "#EXTM3U", see http://don-guitar.blogspot.de/2011/11/creating-playlists-for-sansa-clip-using.html
        print M3U "#EXTM3U\n";
        foreach (@files) {
            # normalize filename
            my($filename, $directories, $suffix) = fileparse($_);
            my $trgName = $filename;
            $trgName =~ s/[^a-zA-Z0-9-_. ]//g; # remove special chars
            # XXX: filenames >255 chars..^^

            # copy and write playlist
            system("cp -up -- \"$musicHome/$_\" \"$targetFolder/$trgName\""); # no perl function for this -.-
            print M3U "$trgName\n";
        }
        close(M3U);
    }
} # 1}}}

main();
