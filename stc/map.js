function viewMap(mapid) {
    var target = "/app/map/view/" + mapid;
    forbidSave();

    new Ajax.Request(target, {
        method: "post",
        parameters: {
            "cache-token": new Date() - Math.random(),            
            "map-only": document.location.pathname.match(/\/mapedit\//) != null ? 0 : 1,
        },
        onSuccess: function(transport) {
            state = transport.responseText.evalJSON();

            if (state.error.length) {
                $("map").hide();
                $("error").innerHTML = state.error.join("<br>");
            } else {
                $("map").show();
                updateMapId(state.mapid, true);
                drawMap();
                drawFactionVP();
                drawGamesPlayed();
                drawFactionInfo();
                if ($("map-data")) {
                    $("map-data").value = state.mapdata;
                }

                // Hack around keyboard / wheel scrolling in Chrome
                // 34+ not working after page load.
                window.scrollTo(0, 50);
            }
        }
    });
}

function previewMap() {
    var target = "/app/map/preview/";
    forbidSave();

    new Ajax.Request(target, {
        method: "post",
        parameters: {
            "cache-token": new Date() - Math.random(),
            "map-data": $("map-data").value,
        },
        onSuccess: function(transport){
            state = transport.responseText.evalJSON();

            if (state.error.length) {
                $("map").hide();
                $("error").innerHTML = state.error.join("<br>");
                document.location.hash = '';
            } else {
                $("map").show();
                updateMapId(state.mapid, state.saved);
                drawMap();
                $("map-data").value = state.mapdata;
                allowSave();
                document.location.hash = state.mapdata.gsub(',', '').
                    gsub(/[ \t\n\r]/, '').
                    gsub(';', '.');
            }
        }
    });
}

function saveMap(mapid) {
    var target = "/app/map/save/";
    forbidSave();

    new Ajax.Request(target, {
        method: "post",
        parameters: {
            "cache-token": new Date() - Math.random(),
            "map-data": $("map-data").value,
        },
        onSuccess: function(transport) {
            $("map").show();
            state = transport.responseText.evalJSON();

            if (state.error.length) {
                $("error").innerHTML = state.error.join("<br>");
            } else {
                document.location = "/mapedit/" + state.mapid;
            }
        }
    });
}

function allowSave() {
    if (!$("save")) {
        return;
    }

    $("save").disabled = false;
}

function forbidSave() {
    if (!$("save")) {
        return;
    }

    $("save").disabled = true;
}

function updateMapId(id, saved) {
    var elem = null;

    if (saved) {
        elem = new Element("a", { "href": "/mapedit/" + id}).updateText(id);
    } else {
        elem = new Element("span").updateText(id);
    }

    $("map-id").updateText("");
    $("map-id").insert(elem);
}

function showMap() {
    var mapid = document.location.pathname.sub(/\/map(edit)?\//, '');
    if (mapid) {
        viewMap(mapid);
    } else if (document.location.hash != '') {
        var str = document.location.hash.gsub('#', '');
        var rows = str.split('.').map(function (row) {
            return row.split('').join(',');
        });
        if (rows[rows.length - 1] != "") {
            rows.push("");
        }
        state = {
            mapdata: rows.join(";\n")
        };
        if ($("map-data")) {
            $("map-data").value = state.mapdata;
        }
        previewMap();
        // document.location.hash = state.mapdata.gsub(',', '').
        //     gsub(/[ \t\n\r]/, '').
        //     gsub(';', '.');
    }
}

function drawFactionVP() {
    var table = $("faction-vp");

    if (!table) {
        return;
    }

    if (!state.vp_setup) {
        return;
    }

    var header = new Element("tr");
    header.insert(new Element("td").updateText("Faction"));
    header.insert(new Element("td").updateText("Starting VP"));
    table.insert(header);
    $H(state.vp_setup).sortBy(function (record) {
        return -record[1];
    }).each(function (record) {
        var faction = record[0];
        var vp = record[1];

        var tr = new Element("tr");
        var faction_cell = factionTableCell(faction);
        faction_cell.updateText(faction);
        tr.insert(faction_cell);
        tr.insert(new Element("td").updateText(vp));
        table.insert(tr);
    });    
}

function drawGamesPlayed() {
    var table = $("games-played");

    if (!table) {
        return;
    }

    var header = new Element("tr");
    header.insert(new Element("td").updateText("Game"));
    header.insert(new Element("td").updateText("Round"));
    header.insert(new Element("td", {"colspan": 5}).updateText("Factions"));
    table.insert(header);
    state.games.each(function (game) {
        var tr = new Element("tr");
        var link = new Element("a", {"href": "/game/" + game.id}).
            updateText(game.id)
        if (game.finished) {
            game.round = "over";
        }
        tr.insert(new Element("td").insert(link));
        tr.insert(new Element("td").updateText(game.round));
        game.factions.each(function (faction_info) {
            if (faction_info == null) {
                return;
            }
            var faction_name = faction_info.split(/ /)[0];
            var faction = factionTableCell(faction_name);
            faction.updateText(faction_info);
            tr.insert(faction);
        });
        table.insert(tr);
    });    
}

function drawFactionInfo() {
    var table = $("faction-info-finished");

    if (!table) {
        return;
    }

    var header = new Element("tr");
    header.insert(new Element("td").updateText("Faction"));
    header.insert(new Element("td").updateText("Games"));
    header.insert(new Element("td", { colspan: 3 }).updateText("VP delta"));
    table.insert(header);
    $H(state.vpstats).sortBy(function (data) {
        return -data[1].mean;
    }).each(function (elem) {
        var faction = elem.key;
        var stats = elem.value;

        var tr = new Element("tr");
        tr.insert(factionTableCell(faction));
        tr.insert(new Element("td").updateText(stats.count));
        tr.insert(new Element("td", { style: "text-align: right" } ).updateText(Math.round(stats.mean)));
        tr.insert(new Element("td").updateText("\u00B1"));
        tr.insert(new Element("td").updateText(Math.round(stats.sterr)));

        table.insert(tr);
    });

    var games_played = {};
    console.log(games_played);

    state.games.each(function (game) {
        var count = game.factions.length;
        game.factions.each(function (faction_info) {
            if (faction_info == null) {
                return;
            }
            var faction_name = faction_info.split(/ /)[0];
            if (!games_played[faction_name]) {
                games_played[faction_name] = { 'all': 0, '3': 0, '4': 0, '5': 0 };
            }
            games_played[faction_name]['all']++;
            games_played[faction_name][count]++;
        });
    });    
    table = $("faction-info-started");
    header = new Element("tr");
    header.insert(new Element("td").updateText("Faction"));
    header.insert(new Element("td").updateText("Total"));
    header.insert(new Element("td").updateText("3p"));
    header.insert(new Element("td").updateText("4p"));
    header.insert(new Element("td").updateText("5p"));
    table.insert(header);

    $H(games_played).sortBy(function (elem) {
        return -elem.value.all;
    }).each(function (elem) {
        var faction = elem.key;
        var counts = elem.value;

        var tr = new Element("tr");
        tr.insert(factionTableCell(faction));
        tr.insert(new Element("td").updateText(counts.all));
        tr.insert(new Element("td").updateText(counts[3]));
        tr.insert(new Element("td").updateText(counts[4]));
        tr.insert(new Element("td").updateText(counts[5]));

        table.insert(tr);
    });
}
