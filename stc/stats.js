var state = null;
var id = document.location.pathname;

function showStats() {
    if (state == null) {
        return;
    }

    var displaySettings = {
        player_count: $("settings-player-count").value,
        final_scoring: $("settings-final-scoring").value,
        map: $("settings-map").value,
    }

    var count = 0;

    var faction_aggregate = {
    };

    var highscore_aggregate = {
    };

    var position_aggregate = {
    };

    state.each(function (record) {
        var bucket_key = record[0];
        var data = record[1];

        var player_count = bucket_key.player_count;

        if (displaySettings.player_count != "any") {
            if (player_count.toString() != displaySettings.player_count) {
                return;
            }
        } else if (player_count < 3) {
            return;
        }

        if (bucket_key.final_scoring != displaySettings.final_scoring &&
            displaySettings.final_scoring != "any") {
            return;
        }

        if (bucket_key.map != displaySettings.map &&
            displaySettings.map != "any") {
            return;
        }
            
        var aggregate_record = faction_aggregate[bucket_key.faction];
        if (!aggregate_record) {
            aggregate_record = faction_aggregate[bucket_key.faction] =
                initAggregate();
        }
        addToAggregate(aggregate_record, data);
            
        aggregate_record = position_aggregate[bucket_key.start_position];
        if (!aggregate_record) {
            aggregate_record = position_aggregate[bucket_key.start_position] =
                initAggregate();
        }
        addToAggregate(aggregate_record, data);

        // High scores

        var faction_hs = highscore_aggregate[bucket_key.faction];
        if (!faction_hs) {
            faction_hs = highscore_aggregate[bucket_key.faction] = {
            };
        }

        var hs_aggregate_record = faction_hs[bucket_key.player_count];
        if (!hs_aggregate_record) {
            hs_aggregate_record = faction_hs[bucket_key.player_count] = {
                vp: 0
            };
        }

        if (data.high_score.vp > hs_aggregate_record.vp ||
            (data.high_score.vp == hs_aggregate_record.vp &&
             data.high_score.time < hs_aggregate_record.time)) {
            faction_hs[bucket_key.player_count] = data.high_score;
        }

        count += data.count / bucket_key.player_count;
    });

    finalizeAggregates(faction_aggregate);
    finalizeAggregates(position_aggregate);

    renderFactionStats(faction_aggregate);
    renderHighScores(displaySettings, faction_aggregate, highscore_aggregate);
    renderPositionStats(displaySettings, position_aggregate);

    // $("timestamp").innerHTML = "Last updated: " + state.timestamp;
    $("count").innerHTML = Math.round(count);
}

function initAggregate() {
    return {
        count: 0,
        wins: 0,
        average_vp: 0,
        average_winner_vp: 0,
        average_position: 0,
        average_margin: 0,
    };
}

function addToAggregate(aggregate_record, data) {
    aggregate_record.count += data.count;
    aggregate_record.wins += data.wins;
    aggregate_record.average_vp += data.average_vp;
    aggregate_record.average_winner_vp += data.average_winner_vp;
    aggregate_record.average_position += data.average_position;
    aggregate_record.average_margin += data.average_margin;
}

function finalizeAggregates(aggregate) {
    $H(aggregate).each(function (elem) {
        var record = elem[1];
        var count = record.count;
        record.win_rate = (100 * record.wins / count).toFixed(2);
        record.wins = (record.wins).toFixed(2);

        record.average_position = (record.average_position / count).toFixed(2);
        record.average_loss_vp = ((record.average_winner_vp - record.average_vp) / count).toFixed(2);
        record.average_vp = (record.average_vp / count).toFixed(2);
        record.average_vp_difference = (record.average_margin / count).toFixed(2);
        delete record.average_winner_vp;
    });
}

function renderFactionStats(faction_aggregate) {
    var div = $("faction-stats");
    var table = new Element("table", {"class": "building-table"});

    div.innerHTML = "";
    table.insert("<tr><td>Faction<td>Wins<td>Games<td>Win %<td>Average position<td>Average score<td>Average score difference");

    $H(faction_aggregate).sortBy(function (a) { return -a.value.win_rate } ).each(function(elem) {
        var faction = elem.key;
        var tr = new Element("tr");
        tr.insert(factionTableCell(elem.key));
        tr.insert("<td>#{value.wins}<td>#{value.count}<td>#{value.win_rate}<td>#{value.average_position}<td>#{value.average_vp}<td>#{value.average_vp_difference}".interpolate(elem));

        table.insert(tr);
    });

    div.insert(table);
}

function renderHighScores(displaySettings, faction_aggregate, highscore_aggregate) {
    var div = $("high-scores");
    div.innerHTML = "";

    var table = new Element("table", {"class": "building-table"});
    var header = new Element("tr");
    header.insert(new Element("td").updateText("Faction"));

    var cols = displaySettings.player_count == "any" ? [3, 4, 5] : [ displaySettings.player_count ];
    cols.each(function (count) {
        header.insert(new Element("td").updateText(count + "p"));        
    });
    table.insert(header);

    $H(faction_aggregate).sortBy(function (a) { return -a.value.win_rate } ).each(function(elem) {
        var faction = elem.key;
        var row = new Element("tr");
        row.insert(factionTableCell(faction));

        cols.each(function(count) {
            var high_score = highscore_aggregate[faction][count];
            if (!high_score) {
                row.insert(new Element("td"));
                return;
            }

            var score = high_score.vp;
            var game = high_score.game;
            var player = high_score.player;
            var gamelink = new Element("a", { href: "/game/" + game }).updateText(score);
            var playerlink = null;
            if (player) {
                playerlink = new Element("a", { 'class': 'static-color',
                                                href: "/player/" + player }).updateText(player);
            }
            row.insert(new Element("td").insert(gamelink).
                       insertTextSpan(" ").insert(playerlink));
        });

        table.insert(row);
    });

    div.insert(table);
}

function renderPositionStats(displaySettings, position_aggregate) {
    var div = $("start-position-stats");
    div.innerHTML = "";
    
    if (displaySettings.player_count == "any") {
        div.insert(new Element("p").updateText("Start position statistics only available for specific player counts"));
        return;
    }

    var table = new Element("table", {"class": "building-table"});
    var header = new Element("tr");
    header.insert(new Element("td").updateText("Position"));
    header.insert(new Element("td").updateText("Wins"));
    header.insert(new Element("td").updateText("Games"));
    header.insert(new Element("td").updateText("Win %"));
    header.insert(new Element("td").updateText("Average position"));
    header.insert(new Element("td").updateText("Average score"));
    header.insert(new Element("td").updateText("Average loss"));
    table.insert(header);

    $H(position_aggregate).each(function (elem) {
        var position = elem.key;
        var record = elem.value;
        var row = new Element("tr");

        row.insert(new Element("td").updateText(position));
        row.insert(new Element("td").updateText(record.wins));
        row.insert(new Element("td").updateText(record.count));
        row.insert(new Element("td").updateText(record.win_rate));
        row.insert(new Element("td").updateText(record.average_position));
        row.insert(new Element("td").updateText(record.average_vp));
        row.insert(new Element("td").updateText(record.average_vp_difference));
        table.insert(row);
    });

    div.insert(table);
}

function showLinks(id) {
    $(id + "-links").style.display = "block";
    $(id + "-show-link").style.display = "none";
}

function loadStats() {
    new Ajax.Request("/data/stats.json", {
        method:"get",
        onSuccess: function(transport){
            state = transport.responseText.evalJSON();
            try {
                showStats();
            } catch (e) {
                handleException(e);
            };
        }
    });
}
