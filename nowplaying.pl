# move to ~/.purple/plugins

use Purple;

%PLUGIN_INFO = ( #  {{{
    perl_api_version => 2,
    name => "Now playing support for mpd",
    version => "0.1",
    summary => "/np",
    description => "/np",
    author => "Giuliano Schneider <gs93\@gmx.net>",
    url => "https://bitbucket.org/gs93/scripts",
    load => "plugin_load",
    unload => "plugin_unload",
); # }}}

sub debug { # {{{
    Purple::Debug::info("nowplaying", "@_\n");
} # }}}

sub plugin_init { # {{{
    return %PLUGIN_INFO;
} # }}}

sub plugin_load { # {{{
    my $plugin = shift;
    debug("plugin loaded");
    Purple::Cmd::register($plugin, 
        "np", # /command
        "", # command expect arguments: s for string, other?
        Purple::Cmd::Priority::DEFAULT,
        Purple::Cmd::Flag::IM | Purple::Cmd::Flag::CHAT,
        0,
        \&now_playing_handler,
        "np:  Display now playing", # description
        $plugin);
} # }}}

sub plugin_unload { # {{{
    my $plugin = shift;
    debug("plugin unloaded");
} # }}}

sub now_playing_handler { # {{{
    debug("now playing invoked");
    my ($conv, $cmd, $plugin, @args) = @_;
    my $sendmsg = $conv->get_im_data();
    # XXX: mpc instead of ncmpcpp, or direct connection to mpd (http://www.perlfect.com/articles/telnet.shtml)
    # alternative: configuration window for the user
    my $msg = `ncmpcpp --now-playing '{{%t}{ by %a}{ from %b}}|{%f}{ (%l)}'`;
    chop($msg); # remove \n
    $sendmsg->send("/me " . $msg);
    #$sendmsg->write("", "blabla", Purple::Conversation::Flags::SYSTEM, 0); #  NO_LOG for grey text
    return Purple::Cmd::Ret::OK;
} # }}}

