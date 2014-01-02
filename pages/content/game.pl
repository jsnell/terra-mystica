{
    layout => 'topbar',
    scripts => [ "/stc/common.js",
                 "/stc/faction.js",
                 "/stc/game.js"],
    title => 'Public View',
    content => read_then_close(*DATA)
}

__DATA__
