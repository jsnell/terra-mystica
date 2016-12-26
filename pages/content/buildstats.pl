{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/faction.js",
                 "/stc/game.js",
                 "/stc/map.js",
                 "/stc/buildstats.js"],
    title => 'Faction Heat Map',
    content => read_then_close(*DATA)
}

__DATA__
<div id="error"></div>

<div>
  Map: <select id=mapid onchange='updateBuildHeatmap()'></select>
  Faction: <select id=factionid onchange='updateBuildHeatmap()'></select>
  Rank: <select id=rankid onchange='updateBuildHeatmap()'></select>
  Games: <span id=gamescount></span>
</div>

<div id="map-container">
  <canvas id="map" width="1600" height="1000">
    Browser not supported.
  </canvas>
</div>
</div>
</div>
<script>
  loadBuildHeatmap();
</script>
