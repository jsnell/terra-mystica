{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/stats.js"],
    title => 'Statistics',
    content => read_then_close(*DATA)
}

__DATA__
<div id="error"></div>

<h4>Settings</h4>

<div class="stats-settings">
  Player count<br>
  <select id="settings-player-count" onchange="showStats()">
    <option value="any" selected="true">3-5p
    <option value="2">2p
    <option value="3">3p
    <option value="4">4p
    <option value="5">5p
  </select>
</div>

<div class="stats-settings">
  Final scoring<br>
  <select id="settings-final-scoring" onchange="showStats()">
    <option value="any" selected="true">Any
    <option value="original">Original
    <option value="expansion">Expansion
  </select>
</div>

<div class="stats-settings">
  Map<br>
  <select id="settings-map" onchange="showStats()">
    <option value="any" selected="true">Any
    <option value="126fe960806d587c78546b30f1a90853b1ada468">Original
    <option value="91645cdb135773c2a7a50e5ca9cb18af54c664c4">Original [2017 vp]
    <option value="95a66999127893f5925a5f591d54f8bcb9a670e6">Fire &amp; Ice Side 1
    <option value="be8f6ebf549404d015547152d5f2a1906ae8dd90">Fire &amp; Ice Side 2
    <option value="fdb13a13cd48b7a3c3525f27e4628ff6905aa5b1">Loon Lakes v1.6
  </select>
</div>

<div class="stats-settings">
  Rating<br>
  <select id="settings-rating" onchange="showStats()">
    <option value="0" selected="true">All games
    <option value="1000">All players rated 1000+
    <option value="1250">All players rated 1250+
  </select>
</div>

<p>
Statistics computed from <span id="count">?</span> finished games.

<h4>Faction Statistics</h4>

<div id="faction-stats">
</div>

<h4>High Scores</h4>
<div id="high-scores">
</div>

<h4>Start Position Statistics</h4>
<div id="start-position-stats">
</div>

<div id="timestamp" style="margin-top: 2ex; "></div>

<script language="javascript">loadStats();</script>
