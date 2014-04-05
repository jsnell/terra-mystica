{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/stats.js"],
    title => 'Faction Statistics',
    content => read_then_close(*DATA)
}

__DATA__
<div id="error"></div>

Statistics computed from <span id="count">?</span> finished games.
Only games with at least 3 players are included.
<table id="faction-stats" class="building-table"><tr><td>Faction<td>Wins<td>Games<td>Win %<td>Average position<td>Average score<td>Average loss<td>Games Won</table>
<h4>High Scores</h4>
<div id="high-scores">
  <table id="high-scores-standard" class="building-table"><tr><td>Faction<td>3p<td>4p<td>5p</table>
  <table id="high-scores-non-standard" class="building-table"><tr><td>Faction<td>3p<td>4p<td>5p</table>
</div>
<div style="padding: 10px"><select id="high-score-selector" onchange="selectHighScoreTable()"><option>standard<option>non-standard</select></div>
<h4>Start Position Statistics (3p)</h4>
<table id="position-stats-3p" class="building-table"><tr><td>Position<td>Wins<td>Games<td>Win %<td>Average position<td>Average score<td>Average loss</table>
<h4>Start Position Statistics (4p)</h4>
<table id="position-stats-4p" class="building-table"><tr><td>Position<td>Wins<td>Games<td>Win %<td>Average position<td>Average score<td>Average loss</table>
<h4>Start Position Statistics (5p)</h4>
<table id="position-stats-5p" class="building-table"><tr><td>Position<td>Wins<td>Games<td>Win %<td>Average position<td>Average score<td>Average loss</table>
<div id="timestamp" style="margin-top: 2ex; "></div>
<script language="javascript">loadStats();</script>
