{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/ratings.js"],
    title => 'Ratings',
    content => read_then_close(*DATA)
}

__DATA__
<div id="error"></div>
<div>
<div style="display: inline-block; vertical-align: top">
  <h4>Player Ratings</h4>
  <table id="player-ratings" class="ranking-table"></table>
</div>

<div style="display: inline-block; inline-block; vertical-align: top; margin-left: 5ex">
  <h4>Factions [Original]</h4>
  <table id="faction-ratings-126fe960806d587c78546b30f1a90853b1ada468" class="ranking-table"></table>

  <h4>Factions [F&I 1]</h4>
  <table id="faction-ratings-95a66999127893f5925a5f591d54f8bcb9a670e6" class="ranking-table"></table>

  <h4>Factions [F&I 2]</h4>
  <table id="faction-ratings-be8f6ebf549404d015547152d5f2a1906ae8dd90" class="ranking-table"></table>

  <h4>Factions [Loon Lakes]</h4>
  <table id="faction-ratings-fdb13a13cd48b7a3c3525f27e4628ff6905aa5b1" class="ranking-table"></table>
</div>

</div>

<h4>FAQ</h4>

<h5>Cool, a rating system! Is this finished?</h5>
<p>
  Not at all. This is an initial attempt, and might get changed
  if it doesn't appear to work well in practice. So don't get
  <i>too</i> attached to your rating.

<h5>How does the ratings system work?</h5>
<p>
  The rating system is loosely based on the Elo system.
  After each game the scores are adjusted based on the
  initial rankings of the players and how well the players
  did. The adjustment is such that you'll make big gains
  when winning against opponents with much higher ranking
  than you and small gains when winning against players with
  a lower ranking. Losses are handled in a similar fashion.
<p>
  There are three differences to a basic Elo system. First,
  the Elo system is for two player games while Terra Mystica
  is a multiplayer game. This is dealt with by considering each
  N player match as consisting of (N/2)*(N-1) separate two player
  matches between each pair of players.
<p>
  Second, the rating computation is actually done both for
  players and factions. If you play a "weak" faction and win,
  you'll get a much bigger ratings boost than if you play a
  "strong" one and win. Likewise the rating of the faction
  will be adjusted based on the results.
<p>
  Third, unlike in basic Elo, the ranking computation is an
  iterative process. First, all matches are processed in the
  order in which the games finished. The all matches are
  processed again, but with a smaller weight. This is done
  both to calibrate the faction rating information, and to
  make the order in which games finish matter less. (TM is a
  much more volatile game than Chess).

<h5>Wait, does that second point mean there's a point in playing the Fakirs?</h5>
<p>
  That's the idea. But of course that assumes that you care
  about the ratings, and that you can at least occasionally
  do well with one of the weaker factions.

<h5>Why did my rating change even though I didn't finish any games?</h5>
<p>
  The ratings are recomputed completely from scratch every day.
  Your rating is affected by the rating of every other player
  and the rating of every faction. If those ratings change,
  yours might as well.
<p>
  At the moment all games will count for your rating. But it's
  possible that at some point older games will start to have
  a lower weigth. This could cause your rating to decay.

<h5>What does the rating number actually mean?</h5>
<p>
  That's a good question. In the original Elo system a 200
  point difference in rating between two players should
  result in the higher rated player winning over the lower
  rated one 75% of the time. However, it's very likely that
  the changes done to the system for this site have destroyed
  that property.

<h5>Why don't I have a rating?</h5>
<p>
  Players with fewer than 5 finished 3-5 player games are
  completely ignored when ratings are computed. They don't have
  one, and don't affect the ratings of others.

<h5>Will playing more games give me a higher rating?</h5>
<p>
  To some extent. All players will start at a rating of 1000,
  and there is a limit to how much the rating can change in a
  single game. So there's a limit to how high your rating can
  go unless you play a certain number of games. But you should
  reach an equilibrium eventually.
  
<h5>Why are the factions in a different order than on the stats page?</h5>
<p>
  The stats page has a simple and transparent metric: how
  often each faction won. The rating system is more
  complicated, and takes into account more factors. First,
  it doesn't only look at wins but at all finishing
  position. Second, it takes into account player
  strength. And third, it takes into account the strengths
  of the opposing factions (e.g. the Alchemists never have
  to play against the Darklings, so the raw win rate of the
  Alchemists might be too optimistic).

<div id="timestamp" style="margin-top: 2ex; "></div>
    </table>
    <script language="javascript">loadRatings();</script>
