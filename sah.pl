#!/usr/bin/perl
# Name        : sah (simple aur helper)
# Version     : 0.1b
# Licenses    : GPL
# Depends on  : perl, perl-www-curl
# Description : search for updates and write package names (and 
#               version numbers) in $XDG_CACHE_HOME/sah

# use declarations {{{1
use strict;
use warnings;

use WWW::Curl::Easy; # curl
use Parse::CPAN::Meta; # json handling
use version; # version comparing
# 1}}}

# config {{{1
our $FILE = (exists($ENV{XDG_CACHE_HOME}) ? $ENV{XDG_CACHE_HOME} : $ENV{HOME} . "/.cache") . "/sah";
our $TIMEOUT = 10;
    # proxy settings {{{2 # XXX: untested
    our $USEPROXY = 0; # 0 = false, 1 = true
    our $PROXY = '127.0.0.1';
    our $PROXYPORT = 1080;
    our $PROXYTYPE = CURLPROXY_HTTP;
    our $PROXYUSERNAME = '';
    our $PROXYPASSWORD = '';
    # 2}}}
our $VERSION = '0.1b';
# 1}}}

# build url {{{1
my $url = 'https://aur.archlinux.org/rpc.php?type=multiinfo';
my %pkgs;
foreach my $pkg (`pacman -Qm`) { # iterate manually installed pkgs
    chop($pkg); # remove last char (\n)
    my ($name, $version) = split(/ /, $pkg, 2);
    $url .= '&arg[]=' . $name; # build url
    $pkgs{$name} = $version;
}
# 1}}}

# curl stuff {{{1
my $curl = WWW::Curl::Easy->new;
my $body;

# setopts {{{2
$curl->setopt(CURLOPT_HEADER, 0); # exclude header
$curl->setopt(CURLOPT_TIMEOUT, $TIMEOUT);
$curl->setopt(CURLOPT_USE_SSL, CURLUSESSL_ALL); # require ssl for all communication or fail
$curl->setopt(CURLOPT_SSL_VERIFYHOST, 2); # cert must be right
$curl->setopt(CURLOPT_USERAGENT, "sah $VERSION");
$curl->setopt(CURLOPT_URL, $url);
$curl->setopt(CURLOPT_WRITEDATA, \$body); # \$ is a reference
if ($USEPROXY) { # set proxy options {{{3
    $curl->setopt(CURLOPT_PROXY, $PROXY);
    $curl->setopt(CURLOPT_PROXYPORT, $PROXYPORT);
    $curl->setopt(CURLOPT_PROXYTYPE, $PROXYTYPE);
    $curl->setopt(CURLOPT_PROXYUSERNAME, $PROXYUSERNAME);
    $curl->setopt(CURLOPT_PROXYPASSWORD, $PROXYPASSWORD);
} # 3}}}
# 2}}}

# starts the actual request
my $retcode = $curl->perform;
# 1}}}

# evaluate results {{{1
if ($retcode == 0) {
    my $response_code = $curl->getinfo(CURLINFO_RESPONSE_CODE);
    if ($response_code == 200) { # check for http statuscode "200 OK"
        open (FILE, ">$FILE"); # open file
        my $jstruct = Parse::CPAN::Meta->load_json_string($body); # parse json
        foreach my $p (@{$jstruct->{results}}) { # iterate results
            # compare versions {{{2
            my $rVersion = $p->{Version}; # remote version
            my $lVersion = $pkgs{$p->{Name}}; # local version
            $rVersion =~ s/[-|:]/./g; # workaround for versions like
            $lVersion =~ s/[-|:]/./g; # 1:2.1 or 3.4-1
            $rVersion = version->new($rVersion);
            $lVersion = version->new($lVersion);
            if ($rVersion > $lVersion) { # compare
                # write updateable pkgs into file
                print FILE $p->{Name} . ' ' . $pkgs{$p->{Name}} . ' -> ' . $p->{Version} . "\n";
            }
            # 2}}}
        }
        close (FILE); # close file
    } else {
        print STDERR "Error: Response code is $response_code\n";
    }
} else {
    print STDERR "Error: " . $curl->strerror($retcode) . " ($retcode) " . $curl->errbuf . "\n";
}
# 1}}}

