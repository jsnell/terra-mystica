function fetchStats(table, type, callback, user) {
    var target = "/app/user/" + type + "/" + user;

    var form_params = {
        "cache-token": new Date() - Math.random(),
        "csrf-token": getCSRFToken(),
    };

    new Ajax.Request(target, {
        method: "post",
        parameters: form_params,
        onSuccess: function(transport){
            var stats = transport.responseText.evalJSON();
            if (stats.error.length) {
                $("error").innerHTML = state.error.join("<br>");
            } else {
                callback(table, stats);
            }
        }
    });
}

function renderStats(table, stats) {
    $H(stats.stats).each(function (elem) {
        var data = elem.value;

        data.ranks = data.ranks.sort();

        var row = new Element("tr");
        ['faction', 'wins', 'count', 'win_percentage', 'mean_vp', 'max_vp', 'ranks'].each(function (field) {
            row.insert(new Element("td").updateText(data[field]));
        });
        table.insert(row);
    });
}

function renderOpponents(table, stats) {
    stats.opponents.each(function (elem) {
        var data = elem;

        var row = new Element("tr");
        ['username', 'count', 'player_better', 'opponent_better', 'draw'].each(function (field) {
            var cell = new Element("td");
            var value = data[field] || "";

            if (field == 'username') {
                cell.insert(new Element("a", {"href": "/player/" + value}).updateText(value));                
            } else {
                cell.updateText(value);
            }
            if (field == 'opponent_better' &&
                data.opponent_better > data.player_better) {
                cell.style.color = '#c00';
            }
            row.insert(cell);
        });
        table.insert(row);
    });
}

var fetched = {};

function selectPlayerTab() {
    var hash = document.location.hash;
    if (!hash) {
        hash = "active"
    } else {
        hash = hash.sub(/#/, '');
    }

    if (!fetched[hash]) {
        if (hash == "active") {
            fetchGames("games-active", "other-user", "running", listGames, user);
        } else if (hash == "finished") {
            fetchGames("games-finished", "other-user", "finished", listGames, user);
        } else if (hash == "stats") {
            fetchStats($("stats-table"), 'stats', renderStats, user);
        } else if (hash == "opponents") {
            fetchStats($("opponents-table"), 'opponents', renderOpponents, user);
        }
        fetched[hash] = true;
    }

    $$("#tabs div").each(function(tab) { tab.hide() });
    $$("#tabs button").each(function(button) { button.style.fontWeight = "" });

    $(hash + "-button").style.fontWeight = "bold";
    $(hash).show();
}

function switchToPlayerTab(tab) {
    document.location.hash = "#" + tab;
    selectPlayerTab();
}
