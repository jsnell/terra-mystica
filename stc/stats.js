var state = null;
var id = document.location.pathname;

function showStats() {
    var count = 0;

    ["all", "3", "4", "5"].each(function(faction_count) {
        $H(state.factions[faction_count]).sortBy(function (a) { return -a.value.win_rate } ).each(function(elem) {
            renderFactionStats("-" + faction_count, elem);
        });
        var label = (faction_count == "all") ? "All" : faction_count + " players";
        var selector = 
            new Element("button", { "id": "faction-stats-selector-" + faction_count}).updateText(label);
        selector.onclick = function() { selectFactionStats(faction_count) } ;
        $("faction-stats-selector").insert(selector);
    });
    selectFactionStats("all");

    $H(state.factions.all).sortBy(function (a) { return -a.value.win_rate } ).each(function(elem) {
        renderHighScoresForFaction(elem.key);
        count += elem.value.wins;
    });
    ["standard", "non-standard"].each(function (label) {
        var selector = 
            new Element("button", { "id": "high-scores-selector-" + label}).updateText(label);
        selector.onclick = function() { selectHighScoreTable(label) } ;
        $("high-scores-selector").insert(selector);
    });
    selectHighScoreTable("standard");

    ["-3p", "-4p", "-5p"].each(function(count) {
        $H(state["positions" + count]).sortBy(function (a) { return -a.value.win_rate } ).each(function(elem) {
            $("position-stats" + count).insert("<tr><td>#{key}<td>#{value.wins}<td>#{value.count}<td>#{value.win_rate}<td>#{value.average_position}<td>#{value.average_vp}<td>#{value.average_loss_vp}</tr>"
                                               .interpolate(elem));
        });
    });

    $("timestamp").innerHTML = "Last updated: " + state.timestamp;
    $("count").innerHTML = Math.round(count);
}

function renderFactionStats(count, elem) {
    var faction = elem.key;
    elem.value.game_links = "";
    (elem.value.games_won || []).each(function (id) {
        elem.value.game_links += ("<a href='/game/" + id + "'>" + id + "</a> ");
    });
    elem.game_link_id_attr = "\"\"".interpolate(elem);

    var tr = new Element("tr");
    tr.insert(factionTableCell(elem.key));
    tr.insert("<td>#{value.wins}<td>#{value.count}<td>#{value.win_rate}<td>#{value.average_position}<td>#{value.average_vp}<td>#{value.average_loss_vp}<td><span id=#{key}-links style='display: none'>#{value.game_links}</span><a href='javascript:showLinks(\"#{key}\")' id=#{key}-show-link>[show]</a>".interpolate(elem));

    $("faction-stats" + count).insert(tr);
}

function renderHighScoresForFaction(faction) {
    ['standard', 'non-standard'].each(function(standard) {
        var row = new Element("tr");
        row.insert(factionTableCell(faction));
        for (var i = 3; i <= 5; ++i) {
            var faction_record = state.factions[i][faction];
            var high_score;
            if (!faction_record ||
                !(high_score = faction_record.high_score[standard])) {
                row.insert(new Element("td"));
                continue;
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
        }
        $("high-scores-" + standard).insert(row);
    });
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

function selectHighScoreTable(kind) {
    $$("#high-scores table").each(function(table) { table.hide() });
    $$("#high-scores-selector button").each(function(button) { button.style.fontWeight = "normal" });

    $("high-scores-" + kind).show();
    $("high-scores-selector-" + kind).style.fontWeight = "bold";
}

function selectFactionStats(count) {
    var kind = $("faction-stats-selector").value;
    $$("#faction-stats table").each(function(table) { table.hide() });
    $$("#faction-stats-selector button").each(function(button) { button.style.fontWeight = "normal" });

    $("faction-stats-" + count).show();
    $("faction-stats-selector-" + count).style.fontWeight = "bold";
}
