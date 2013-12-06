var state = null;
var id = document.location.pathname;

function listGames(games, div, mode, status) {
    $(div).update("<thead><td>Game<td>Faction<td>Last move<td>Round<td>Waiting for<td>Status</thead>");
    var tbody = new Element("tbody");
    var action_required_count = 0;
    $(div).insert(tbody);
    games.each(function(elem) {
        elem.status = "";
        if (elem.action_required) {
            elem.status = "game-status-action-required";
            action_required_count++;
        } else if (elem.unread_chat_messages > 0) {
            elem.status = "game-status-action-unread-chat";
            action_required_count++;
        }
        if (elem.seconds_since_update) {
            elem.time_since_update = seconds_to_pretty_time(elem.seconds_since_update) + " ago";
        }
        if (elem.vp) { elem.vp += " vp"; }
        if (elem.rank) { elem.vp += " (" + elem.rank + ")"; }

        $(tbody).insert("<tr class='#{status}'><td>#{id}<td><a href='#{link}'> #{role}<td>#{time_since_update}</a><td>#{round}<td>#{waiting_for}<td>#{vp}</tr>"
                        .interpolate(elem));
    });
    if (mode == "user") {
        var link = new Element('a', {"href": "#", "accesskey": "n"}).update("Refresh");
        link.onclick = function() { fetchGames(div, mode, status, nextGame); } 
        var td = new Element('td').insert(link);
        var tr = new Element('tr').insert(new Element("td")).insert(td);
        $(tbody).insert(tr);

        if (status == "running") {
            moveRequired = (action_required_count > 0);
            setTitle();
        }
    }
}

function nextGame(games, div, mode, status) {
    games.each(function(elem) {
        if (elem.action_required) { document.location = elem.link; }
    });
    listGames(games, div, mode, status);
}

