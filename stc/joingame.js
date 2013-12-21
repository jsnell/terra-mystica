var state;

function joinGame(id, status) {
    disableDescendants($("games"));    
    new Ajax.Request("/cgi-bin/joingame.pl", {
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
                if (!resp.error) {
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

