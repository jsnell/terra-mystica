{
    layout => 'sidebar',
    scripts => [ "/stc/common.js"],
    title => 'Playtest Faction Info',
    require_access => 'restricted',
    content => read_then_close(*DATA)
}

__DATA__
<body style="max-width: 75ex">

<h3>Terrain</h3>

<h4>Terrain: Ice</h4>

<p>
When a ice faction is picked, they immediately choose one of the normal
7 terrain types (e.g. red) that hasn't yet been picked. Factions of that
color are not available to be picked during the setup.

<p>
During initial dwelling placement, the ice factions get to place dwellings
on hexes their chosen terrain (which will be transformed to ice for free).
After the initial setup they have to use spades to transform as normal.
Transforming works almost as normal, e.g. if the ice faction chose red
during the setup, it costs 1 spade to transform yellow/gray to ice, 2
spades to transform brown/green, etc. However, transforming their chosen
color to ice also costs 1 spade.

<p>
Once a hex has been transformed to ice, it can never be transformed to
any other terrain type.

<h4>Terrain: Volcano</h4>

<p>
Like the ice factions, a volcano faction needs to choose an unpicked
color.  However, they choose their color after all factions have been
selected rather than immediately. They place their initial dwellings
on hexes of that type, which get immediately transformed to
volcanos. After the initial dwelling placement the volcano factions
must transform spaces to volcanos using their special power.

<p>
The volcano factions have no digging track to advance on, can't use
the dig command to generate spades, and never pay spades to
transform. Instead they will use their special powers to transform
hexes directly to volcanos. If a volcano faction receives spades from
some source (bonus tile, cult bonus, power action, etc), they'll get
some other benefit instead. Note that the transformation costs of the
volcano factions do not depend at all on the transformation cycle, but
on other factors (explained in faction description).

<p>
Using the special power to transform a hex to a volcano doesn't count
as using spades for the purposes of a round scoring tile. Likewise
receiving a spade from a bonus tile or a power action doesn't count
as using the spade, and thus doesn't generate any points.

<p>
Once a hex has been transformed to a volcano, it can never be transformed
to another terrain type.

<h3>Factions</h3>

<h4>Ice Maidens</h4>

<ul>
<li> Start with 6/6/0 power, 0/1/0/1 on cults
<li> Start with a favor tile (taken immediately on faction selection)
<li> Advancing on the digging track requires just 5c+1p, no workers
<li> SH produces 4power, +3vp per temple when passing
<li> The 8th dwelling produces a worker
</ul>

<h4>Yetis</h4>

<ul>
<li> Start with 0/12/0 power, 0/0/1/1 on cults
<li> Have a discount of one power on the power actions (so act4 costs 3pw, not 4pw)
<li> Advancing on the digging track requires just 5c+1w+1p.
<li> SH produces 4pw, and allows the Yetis to take any power action that they can pay for, even if it has already been taken during that round. The same power action can be taken multiple times, regardless of how many times and by whom it has been taken.
<li> The SH and SA have a power level of 4 for leeching / forming towns, instead of the normal 3
<li> Every TP produces 2pw+2c
<li> The 8th dwelling produces a worker
</ul>

<h4>Acolytes</h4>

<ul>
<li> Start with 6/6/0 power, 3/3/3/3 on cults
<li> Start with 1 extra worker, but produce one worker less.
<li> Pay cult steps to transform. 4 steps on a single cult if transforming from another player's home terrain to a volcano, 3 steps if transforming from some other color. (The ice factions do not have a home terrain).
<li> SH produces 2pw, and gives the Acolytes one extra cult step for each priest sent to the cult tracks
<li> If the Acolytes gain a spade from somewhere, they'll gain a cult step instead.
<li> The Acolytes are unique in that they can go down on cult tracks. They do not gain power from the cult track thresholds when going down, but can gain the same reward multiple times when going up. If they leave the 10 space, it's free for another player to take.
</ul>

<h4>Dragon Masters</h4>

<ul>
<li> Start with 4/4/0 power, 2/0/0/0 on cults, and only 2 workers
<li> Permanently remove power tokens (from any bowl) to transform. 2 tokens if transforming from another player's home terrain to a volcano, 1 token if transforming from some other color. (The ice factions do not have a home terrain).
<li> SH produces 2pw, and gives an instant one-time production of as many power tokens as there are players (tokens go into bowl 1).
<li> 4th dwelling produces no worker income.
<li> If the Dragon Masters gain a spade from somewhere, they'll gain a power token into bowl 1 instead.
</ul>

</body>
