var state = null;
var id = document.location.pathname;

function showStats() {
    var count = 0;
    $H(state.factions).sortBy(function (a) { return -a.value.win_rate } ).each(function(elem) {
        elem.value.game_links = "";
        (elem.value.games_won || []).each(function (id) {
            elem.value.game_links += ("<a href='/game/" + id + "'>" + id + "</a> ");
        });
        elem.game_link_id_attr = "\"\"".interpolate(elem);

        $("faction-stats").insert("<tr><td>#{key}<td>#{value.wins}<td>#{value.count}<td>#{value.win_rate}<td>#{value.average_position}<td>#{value.average_vp}<td>#{value.average_loss_vp}<td><span id=#{key}-links style='display: none'>#{value.game_links}</span><a href='javascript:showLinks(\"#{key}\")' id=#{key}-show-link>[show]</a></tr>"
                                  .interpolate(elem));
        count += elem.value.wins;
        {
            var row = new Element("tr");
            row.insert(new Element("td").updateText(elem.key));
            for (var i = 3; i <= 5; ++i) {
                var score = elem.value.high_score[i].vp;
                var game = elem.value.high_score[i].game;
                var player = elem.value.high_score[i].player;
                var gamelink = new Element("a", { href: "/game/" + game }).updateText(score);
                var playerlink = null;
                if (player) {
                    playerlink = new Element("a", { 'class': 'static-color',
                                                    href: "/player/" + player }).updateText(player);
                }
                row.insert(new Element("td").insert(gamelink).
                           insertTextSpan(" ").insert(playerlink));
            }
            $("high-scores").insert(row);
        }

    });
    ["-3p", "-4p", "-5p"].each(function(count) {
        $H(state["positions" + count]).sortBy(function (a) { return -a.value.win_rate } ).each(function(elem) {
            $("position-stats" + count).insert("<tr><td>#{key}<td>#{value.wins}<td>#{value.count}<td>#{value.win_rate}<td>#{value.average_position}<td>#{value.average_vp}<td>#{value.average_loss_vp}</tr>"
                                               .interpolate(elem));
        });
    });
    $("timestamp").innerHTML = "Last updated: " + state.timestamp;
    $("count").innerHTML = Math.round(count);
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
