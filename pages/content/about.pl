{
    layout => 'sidebar',
    scripts => [ "/stc/common.js"],
    title => 'About',
    content => read_then_close(*DATA)
}

__DATA__
<p>
  This is an unofficial automated moderator tool
  for <a href="https://boardgamegeek.com/boardgame/120677/terra-mystica">Terra
  Mystica</a>, a game by Helge Ostertag and Jens
  Dr&ouml;gem&uuml;ller published by Feuerland Spiele.
</p>

<p>
  Terra Mystica is a trademark of Frank Heeren (Feuerland
  Spiele).
</p>

<p>
  The site was created
  by <a href="https://www.snellman.net/">Juho
  Snellman</a>. The source code is available on
  <a href="https://github.com/jsnell/terra-mystica/">github</a>.
</p>
