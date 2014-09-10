{
    layout => 'sidebar',
    scripts => [ "/stc/common.js"],
    title => 'Playtest Scoring Rules',
    require_access => 'restricted',
    content => read_then_close(*DATA)
}

__DATA__
<body style="max-width: 75ex">

<p>
There are 4 new scoring methods, each scoring 18/12/6vp to the 1st/2nd/3rd
place at the end of the game. One of the scoring methods is randomly chosen
to be in the game in the start. The remaining three are not used.

<ul>
<li>Number of separate clusters in one network of connected buildings. (Where a cluster is a group of directly connected buildings). All fragments of a mermaid town that crosses a river are part of the same cluster.
<li>Largest distance between two buildings in one network of connected buildings
<li>Largest distance between a stronghold and sanctuary, which are in the same network of connected buildings
<li>Number of buildings on the edge of the map which are in the same network of connected buildings
</ul>

<p>
"Distance" is defined as the shortest hex-by-hex path from hex A
to hex B, ignoring terrain and rivers. The distance between two given
hexes will always be the same no matter what the game state is. That
is, bridges, shipping level, or faction special abilities don't
matter.

<p>
You need to achieve the goal at some level to score any points, just
like a 0 on the cults scores nothing even if it's technically a tied
3rd place. For example with a SA/SH distance scoring, all players
without a SA and SH in the same network will score no points.

<p>
For example <a href=http://terra.snellman.net/game/jan30 target=_blank>in this game</a>
you'd have the following scoring:

<p>  
For number of clusters:

<pre>
18 - Dwarves: 7
12 - Mermaids: 3 (the mermaid special towns give direct adjacency)
 6 - Cultists: 1 (the 2 clusters are not connected)
</pre>

For distance:

<pre>
18 - Dwarves: 11 (I3-C5)
12 - Mermaids: 10 (I2-C4)
 6 - Cultists: 3 (G4-E10)
</pre>

For distance-sa-sh:

<pre>
18 - Mermaids: 4 (E4-D5)
12 - Cultists: 1 (E5-E6)
 0 - Dwarves: 0 -> no points
</pre>

For edge:

<pre>
18 - Mermaids: 4
12 - Dwarves: 2
 6 - Cultists: 1
</pre>


