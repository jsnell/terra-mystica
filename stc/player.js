function fetchStats(table, type, callback, user) {
    var target = "/app/user/" + type + "/" + user;

    var form_params = {
        "cache-token": new Date() - Math.random(),
        "csrf-token": getCSRFToken(),
    };

    new Ajax.Request(target, {
        method: "post",
        parameters: form_params,
        onSuccess: function(transport) {
            var response = transport.responseText.evalJSON();
            if (response.error.length) {
                $("error").innerHTML = response.error.join("<br>");
            } else if (response.link) {
                document.location = response.link;
            } else {
                callback(table, response);
            }
        }
    });
}

function renderStats(table, stats) {
    $H(stats.stats).each(function (elem) {
        var data = elem.value;

        data.ranks = data.ranks.sort();

        var row = new Element("tr");
        row.insert(factionTableCell(data.faction));
        ['wins', 'count', 'win_percentage', 'mean_vp', 'max_vp', 'ranks'].each(function (field) {
            row.insert(new Element("td").updateText(data[field]));
        });
        table.insert(row);
    });
}

function renderMetadata(table, stats) {
    var metadata = stats.metadata;
    table.insert(new Element("tr").insert(
        new Element("td").updateText("Username")).insert(
            new Element("td").updateText(metadata.username)));
    table.insert(new Element("tr").insert(
        new Element("td").updateText("Display Name")).insert(
            new Element("td").updateText(metadata.displayname)));
    table.insert(new Element("tr").insert(
        new Element("td").updateText("Rating")).insert(
            new Element("td").updateText(metadata.rating || '-')));
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
        hash = "metadata"
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
        } else if (hash == "metadata") {
            fetchStats($("metadata-table"), 'metadata', renderMetadata, user);
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
