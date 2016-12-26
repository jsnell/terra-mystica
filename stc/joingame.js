var state;

function joinGame(id, status) {
    disableDescendants($("games"));    
    new Ajax.Request("/app/join-game/", {
        parameters: {
            "cache-token": new Date(),
            "csrf-token": getCSRFToken(),
            "game": id,
        },
        method: "post",
        onSuccess: function(transport){
            enableDescendants($("games"));
            try {
                var resp = transport.responseText.evalJSON();
                state = resp;
                if (resp.error.size()) {
                    status.style.color = "red";
                    status.update(resp.error.join("<br>"));
                } else {
                    status.style.color = "green";
                    status.updateText("ok");
                }
            } catch (e) {
                handleException(e);
            };
        }
    });    
}

function showOpenGames(games) {
    var table = $("games");
    table.update("");

    if (games.size() == 0) {
        table.update("There are currently no open games. Maybe you should create a <a href='/newgame/'>new game</a>?");
        return;
    }

    var header = new Element("tr");
    header.insert(new Element("td", {"style": "width: 8ex"}).updateText("ID"));
    header.insert(new Element("td", {"style": "width: 8ex"}).updateText("Players"));
    header.insert(new Element("td", {"style": "width: 32ex"}).updateText("Description"));
    header.insert(new Element("td", {"style": "width: 32ex"}).updateText("Options"));
    header.insert(new Element("td", {"style": "width: 8ex"}).updateText("Action"));
    header.insert(new Element("td", {"style": "width: 20ex"}).updateText("Status"));
    table.insert(header);

    games.each(function (game) {
        var row = new Element("tr");
        row.insert(new Element("td").update(
            new Element("a", {"href": "/game/" + game.id}).updateText(game.id)));
        game.player_count = game.players.size();
        var players = new Element("td").updateText("#{player_count}/#{wanted_player_count}".interpolate(game))
        game.players.each(function (username) {
            var player = new Element("div").
                insert(new Element("a", {"href": "/player/" + username}).
                       updateText(username));
            players.insert(player);
        });
        row.insert(players);
        row.insert(new Element("td").updateText(game.description));
        {
            var cell = new Element("td");

            if (game.chess_clock_hours_initial != null) {
                var style = "";
                cell.insert(new Element("div", {style: style}).updateText(
                    "Chess clock " +
                        seconds_to_pretty_time((game.chess_clock_hours_initial) * 3600) +
                        " + " +
                        seconds_to_pretty_time((game.chess_clock_hours_per_round) * 3600) +
                        " per round, grace period " +
                        seconds_to_pretty_time((game.chess_clock_grace_period) * 3600)))
            } else {
                var hours = game.deadline_hours || 168;
                var style = "";
                if (hours <= 1*24) {
                    style = "color: #f00; font-weight: bold";
                } else if (hours <= 3*24) {
                    style = "color: #f00";
                }
                cell.insert(new Element("div", {style: style}).updateText(
                    "Move timer " + seconds_to_pretty_time((hours) * 3600)));
            }

            if (game.map_variant) {
                var label = mapNamesById[game.map_variant] || "Alternate";
                var div = new Element("div");
                div.insert(new Element("span").update("map "));
                div.insert(new Element("a", {href:"/map/" + game.map_variant}).updateText(label));
                cell.insert(div);
            }

            if (game.minimum_rating) {
                cell.insert(new Element("div").updateText(
                    "Minimum rating " + game.minimum_rating));
            }
            if (game.maximum_rating) {
                cell.insert(new Element("div").updateText(
                    "Maximum rating " + game.maximum_rating));
            }

            var pretty_option = {
                "mini-expansion-1": "Mini Expansion (town tiles)",
                "shipping-bonus": "Shipping bonus tile (Spielbox 6/2013)",
                "temple-scoring-tile": "Temple round scoring tile (2015 mini expansion)",
                "fire-and-ice-final-scoring": "Extra final scoring tile",
                "variable-turn-order": "Turn order determined by passing order",
                "fire-and-ice-factions/ice": "Ice factions",
                "fire-and-ice-factions/variable_v4": "Variable factions (<a href='/factioninfo/'>playtest</a> v4)",
                "fire-and-ice-factions/variable_v5": "Variable factions (with <a href='https://boardgamegeek.com/thread/1456706/official-change-rules'>official rules change</a>)",
                "fire-and-ice-factions/volcano": "Volcano factions",
            };

            if (game.game_options) {
                cell.insert(new Element("br"));
                game.game_options.sort().each(function (elem) {
                    if (elem == "email-notify" ||
                        elem == "strict-leech" ||
                        elem == "strict-darkling-sh" ||
                        elem == "strict-chaosmagician-sh" ||
                        elem == "errata-cultist-power") {
                        return;
                    }
                    cell.insert(new Element("div", {style: "white-space: nowrap;"}).update(pretty_option[elem] || elem));
                });
            }

            row.insert(cell);
        }
        var join = new Element("button").updateText("Join");
        var status = new Element("span");
        join.onclick = function() {
            joinGame(game.id, status);
        }
        row.insert(new Element("td").insert(join));
        row.insert(new Element("td").insert(status));

        table.insert(row);
    });
}

function fetchOpenGames() {
    new Ajax.Request("/app/list-games/", {
        parameters: {
            "cache-token": new Date(),
            "mode": "open",
        },
        method: "get",
        onSuccess: function(transport){
            try {
                var resp = transport.responseText.evalJSON();
                if (!resp.error || !resp.error.size()) {
                    showOpenGames(resp.games);
                } else {
                    $("error").update(resp.error);
                }
            } catch (e) {
                handleException(e);
            };
        }
    });
}

