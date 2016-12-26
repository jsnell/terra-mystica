var builds;

function updateHeatmapOptions(hash) {
    var factions = {};
    $H(builds).sortBy(function(elem) {
        return (mapNamesById[elem.key] || elem.key)
    } ).each(function(elem) {
        if (!mapNamesById[elem.key]) {
            return;
        }
        $("mapid").insert("<option value=" + elem.key + ">" +
                          (mapNamesById[elem.key] || elem.key) + "</option>")
        $H(elem.value.factions).each(function(elem) {
            factions[elem.key] = 1;
        });
    });
    $H(factions).sortBy(function(a, b) { return a.key }).each(function(elem) {
        var opt = new Element("option", { "value": elem.key }).updateText(
            factionPrettyName[elem.key]);
        setFactionStyleForElement(opt, elem.key);
        $("factionid").insert(opt);
    });

    $("rankid").insert("<option>1</option>");
    $("rankid").insert("<option>2</option>");
    $("rankid").insert("<option>3</option>");
    $("rankid").insert("<option>4</option>");
    $("rankid").insert("<option value='all'>Any</option>");

    if (hash) {
        var hash = hash.substr(1);
        var components = hash.split(',');
        if (components.length) {
            $("mapid").value = components.shift();
        }
        if (components.length) {
            $("factionid").value = components.shift();
        }
        if (components.length) {
            $("rankid").value = components.shift();
        }
    }
}

function updateBuildHeatmap() {
    state = {};
    var by_map = builds[$("mapid").value];
    state.map = by_map.base_map;
    state.bridges = [];
    $H(state.map).each(function(elem) {
        var hex = elem.value;
        hex.label = '';
        if (hex.color != 'white') { hex.forceColor='#fff'; }
    });
    var by_faction = by_map.factions[$("factionid").value][$("rankid").value];
    $H(by_faction.build).each(function(elem) {
        var id = elem.key;
        var hex = state.map[id];
        var freq = elem.value / by_faction.games;
        hex.label = Math.floor(freq * 100) + "%";
        hex.forceColor = "rgb(255, " + Math.floor((1 - freq) * 255) + ", 255)";
    });
    $("gamescount").updateText(by_faction.games);
    drawMap();

    document.location.hash = $("mapid").value + "," + $("factionid").value + "," + $("rankid").value;
    setFactionStyleForElement($("factionid"), $("factionid").value);
}

function loadBuildHeatmap() {
    var target = "/data/buildstats.json";
    new Ajax.Request(target, {
        method: "get",
        parameters: {
            "cache-token": new Date() - Math.random(),            
        },
        onSuccess: function(transport) {
            builds = transport.responseText.evalJSON();
            updateHeatmapOptions(document.location.hash);
            updateBuildHeatmap();
            $("map").show();
        }
    });
}
