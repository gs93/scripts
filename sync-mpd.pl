#!/usr/bin/perl
# Name        : sync-mpd
# Version     : 0.2b
# Licenses    : GPL
# Depends on  : perl

use strict;
use warnings;

use File::Basename;
use Getopt::Long;

my $musicHome = $ENV{HOME} . "/music";
my $playlistFolder = $ENV{HOME} . "/.mpd/playlists";
my @playlistsToSync;
my $targetFolder = "/mnt/clip/MUSIC";
my $dryrun = 0;
my $verbose = 0;

# TODO: trap, see http://www.perlmonks.org/?node_id=93004

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

sub printHelp { # {{{1
    print "Usage: $0 [options]\n";
    print "  -m, --music              music folder (default: $musicHome)\n";
    print "  -p, --playlistfolder     folder with the playlists (default: $playlistFolder)\n";
    print "  -l, --playlist           name of the playlists to sync (default: all)\n";
    print "  -t, --target             target folderi (default: $targetFolder)\n";
    print "  -d, --dryrun             don't write anything, just print\n";
    print "  -v, --verbose            output more information\n";
    print "  -h, --help               print this help\n";
    print "  Example: $0 --dryrun --playlist playlist1 --playlist playlist2 --target /mnt/bla\n";
    exit;
} # 1}}}

sub parseOpts { # {{{1
    # http://perldoc.perl.org/Getopt/Long.html
    my $help = 0;
    GetOptions(
               'music|m=s'          => \$musicHome,
               'playlistfolder|p=s' => \$playlistFolder,
               'playlist|l=s'       => \@playlistsToSync,
               'target|t=s'         => \$targetFolder,
               'dryrun|d'           => \$dryrun,
               'verbose|v+'         => \$verbose,
               'help|h'             => \$help,
              );

    printHelp() if ($help);

    foreach (@playlistsToSync) {
        $_ .= '.m3u';
    }

    if ($verbose >= 1) {
        print "musicHome      : $musicHome\n";
        print "playlistFolder : $playlistFolder\n";
        print "playlists      : @playlistsToSync (" . scalar(@playlistsToSync) . ")\n";
        print "targetFolder   : $targetFolder\n";
        print "dryrun         : $dryrun\n";
        print "\n";
    }
} # 1}}}

sub getReadableSize { # {{{1
    # XXX: dynamic
    return sprintf("%.1f MB", $_[0] / 1024 / 1024);
} # 1}}}

sub main { # {{{1
    parseOpts();
    if (! -d $targetFolder) {
        print STDERR "$targetFolder doesn't exist!\n";
        exit 1;
    }

    my $totalSize = 0;
    # XXX: support for playlist which aren't in the playlistFolder
    foreach (getPlaylists($playlistFolder)) {
        next unless ($_ =~ m/\.m3u$/);
        if (scalar(@playlistsToSync) > 0) {
            my $tmp = $_;
            next unless (grep(/^$tmp$/, @playlistsToSync));
        }
        print "sync $_";
        my $playlistSize = 0;

        open M3U, ">$targetFolder/$_" if (!$dryrun);
        my @files = parsePlaylist("$playlistFolder/$_");

        # playlists start with "#EXTM3U", see http://don-guitar.blogspot.de/2011/11/creating-playlists-for-sansa-clip-using.html
        print M3U "#EXTM3U\n" if (!$dryrun);
        foreach (@files) {
            # normalize filename
            my($filename, $directories, $suffix) = fileparse($_);
            my $trgName = $filename;
            $trgName =~ s/[^a-zA-Z0-9-_. ]//g; # remove special chars
            # XXX: filenames >255 chars..^^
            # XXX: double filenames

            # TODO: delete files which aren't in a playlist

            # copy and write playlist
            my $musicFile = "$musicHome/$_";
            if (!$dryrun) {
                system("cp -u  --preserve=mode,timestamps -- \"$musicFile\" \"$targetFolder/$trgName\""); # no perl function for this -.-
                print M3U "$trgName\n";
            }
            print "copy \"$musicHome/$_\" to \"$targetFolder/$trgName\"\n" if ($verbose >= 2);
            $playlistSize += (-s $musicFile);

        }
        $totalSize += $playlistSize;
        print " (size: " . getReadableSize($playlistSize) . ")\n";
        close(M3U);
    }
    print " -- total size: " . getReadableSize($totalSize) . "\n" if ($verbose >= 1);
} # 1}}}

main();
