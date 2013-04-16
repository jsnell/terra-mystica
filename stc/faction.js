var state = null;
var params = null;
var currentFaction = null;
var backendDomain = null;

function loadGame (domain, pathname) {
    var path = pathname.sub(/\/(faction|game)\//, "").split("/");
    var expected = ["game", "faction", "key"];
    params = {};
    path.each(function(elem) {
        var match = elem.match(/(.*)=(.*)/); 
        if (match) {
            params[match[1]] = match[2]; 
        } else {
            params[expected.shift()] = elem;
        }
    });

    backendDomain = domain;
    state = null;
    
    if ($("title")) {
        $("title").text += " - " + params.game;
        if (params.faction) {
            $("title").text += " / " + params.faction;
        }
    }

    if ($("move_entry")) {
        $("move_entry").innerHTML = '';
    }

    if ($("preview_commands")) {
        $("preview_commands").innerHTML = '';
    }

    currentFaction = params.faction;
    preview();
}

function previewOrSave(save) {
    if ($("move_entry_action")) {
        $("move_entry_action").disabled = true;
    }

    if ($("move_entry_input")) {
        $("move_entry_input").disabled = true;
    }
    var preview = "";

    if ($("move_entry_input")) {
        preview = $("move_entry_input").value;
        $("preview_status").innerHTML = "Previewing the following commands for " + currentFaction;
        $("preview_commands").innerHTML = preview;
    }

    var target = save ? "/cgi-bin/append.pl" : "/cgi-bin/bridge.pl";
    target = "http://" + backendDomain + target;
    if (!save) {
        spin();
    }
    new Ajax.Request(target, {
        method: "get",
        parameters: {
            "game": params.game,
            "preview": preview,
            "faction-key": params.key,
            "preview-faction": currentFaction,
            "max-row": params['max-row']
        },
        onFailure: function(transport){
            state = transport.responseText.evalJSON();
            failed();
        },
        onSuccess: function(transport){
            state = transport.responseText.evalJSON();
            if (save) {
                if (state.error.size() > 0) {
                    failed();
                } else {
                    $("preview_status").innerHTML = "Executed the following commands for " + currentFaction;
                    if (state.email) {
                        $("move_entry").update(new Element("a", {"href": makeMailToLink()}).update("Send email"));
                    } else {
                        $("move_entry").innerHTML = "";
                    }
                    preview(false);
                }
            } else {
                try {
                    draw();
                    moveEntryAfterPreview();
                } catch (e) {
                    handleException(e);
                };
            }
        }
    });
}

function preview() {
    previewOrSave(false);
}

function save() {
    previewOrSave(true);
}

function makeMailToLink() {
    var newline = "%0D%0A";
    var status = $("preview_status").innerHTML;
    var moves = $("preview_commands").textContent.split(/\n/).map(function (x) {
        return "  " + encodeURIComponent(x);
    }).join(newline);
    var actions = $("action_required").childElements().map(function (x) {
        return "  " + encodeURIComponent(x.textContent);
    }).join(newline)
    var footer = "Round #{round}, turn #{turn}".interpolate(state);

    var moves = status + ":" + newline + moves + newline + newline + "Actions required:" + newline + actions + newline + newline + footer;

    var link = "mailto:" + encodeURIComponent(state.email) + "?subject=Re: Terra Mystica PBEM (" + params.game + ")&body=" + moves;

    return link;
}

function showActiveGames(div, mode) {
    var record = { "active_count": 0, "action_required_count": 0 };
    state.games.each(function(elem) {
        if (!elem.finished) { record.active_count++; }
        if (elem.action_required) { record.action_required_count++; }
    });
    $(div).innerHTML = "<div>Moves required in #{action_required_count}/#{active_count} games</div>".interpolate(record);

    var link = new Element('a', {"href": "#", "accesskey": "n"}).update("Next game");
    link.onclick = function() { fetchGames(div, mode, nextGame); } 
    $(div).insert(link);
}

function nextGame(div, mode) {
    state.games.each(function(elem) {
        if (elem.action_required) { document.location = elem.link; }
    });
    showActiveGames(div, mode);
}

function fetchGames(div, mode, handler) {
    $(div).innerHTML = "... loading";
    new Ajax.Request("/cgi-bin/gamelist.pl", {
        parameters: { "mode": mode },
        method:"get",
        onSuccess: function(transport){
            state = transport.responseText.evalJSON();
            try {
                if (!state.error) {
                    handler(div, mode);
                } else {
                    $(div).innerHTML = "<tr><td>" + state.error + "</td>";
                }
            } catch (e) {
                handleException(e);
            };
        }
    });
}

