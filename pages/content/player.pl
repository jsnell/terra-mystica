{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/index.js",
                 "/stc/player.js" ],
    title => 'Player Information',
    content => read_then_close(*DATA)
}

__DATA__

<div id="tabs">
<button id="active-button" onclick="javascript:switchToPlayerTab('active')">Active</button>
<button id="finished-button" onclick="javascript:switchToPlayerTab('finished')">Finished</button>
<button id="stats-button" onclick="javascript:switchToPlayerTab('stats')">Stats</button>

<div id="active" style="display: none">
    <h4>Active / Recently Finished Games</h4>
    <table id="games-active" class="gamelist"></table>
</div>

<div id="finished" style="display: none">
    <h4>Finished Games</h4>
    <table id="games-finished" class="gamelist"></table>
</div>

<div id="stats" style="display: none">
    <h4>Faction Statistics</h4>
    <table id="stats-table" class="building-table"><tr><td>Faction<td>Wins<td>Games<td>Win %<td>Average score<td>Max score<td>Ranks</tr></table>
</div>
</div>

<script language="javascript">
  var path = document.location.pathname.split("/");
  var user = path[2];

  $("heading").innerHTML += " - " + user;
  
  selectPlayerTab();
</script>
