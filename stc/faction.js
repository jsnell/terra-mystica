var state = null;
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

    setTitle();
    
    if ($("move_entry")) {
        $("move_entry").innerHTML = '';
    }

    if ($("preview_commands")) {
        $("preview_commands").innerHTML = '';
    }

    currentFaction = params.faction;
    preview();
}

function previewOrSave(save, preview_data, prefix_data) {
    dataEntrySetStatus(true);

    if (preview_data) {
        $("preview_status").innerHTML = "Previewing the following commands for " + currentFaction;
        $("preview_commands").innerHTML = preview_data;
    }

    var target = save ? "/cgi-bin/append.pl" : "/cgi-bin/bridge.pl";
    target = "http://" + backendDomain + target;
    if (!save) {
        spin();
    }
    new Ajax.Request(target, {
        method: "get",
        parameters: {
            // Thanks, Chrome on Android. I'm sure that randomly
            // ignoring cache control headers is *just* the right
            // thing.
            "cache-token": new Date() - Math.random(),
            "game": params.game,
            "preview": prefix_data + preview_data,
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
                        $("move_entry").update("<br>");
                        $("move_entry").insert(new Element("a", {"href": makeMailToLink()}).update("Send email"));
                    } else {
                        $("move_entry").innerHTML = "";
                    }
                    fetchGames($("user-info"), "user", "running",
                               showActiveGames);
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

function previewPlan() {
    var prefix_data = "start_planning.";
    var preview_data = $("planning_entry_input").value;
    previewOrSave(false, preview_data, prefix_data);
}

function preview() {
    var preview_data = $("move_entry_input") ? $("move_entry_input").value : "";
    previewOrSave(false, preview_data, "");
}

function save() {
    var preview_data = $("move_entry_input").value;
    previewOrSave(true, preview_data, "");
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

function showActiveGames(games, div, mode, status) {
    var record = { "active_count": 0, "action_required_count": 0 };
    moveRequired = false;
    games.each(function(elem) {
        if (!elem.finished) { record.active_count++; }
        if (elem.action_required) {
            moveRequired = true;
            record.action_required_count++;
        }
    });
    $(div).innerHTML = "<div style='display: block-inline; margin-right: 10px'>Moves required in #{action_required_count}/#{active_count} games</div>".interpolate(record);

    var link = new Element('a', {"href": "#", "accesskey": "n"}).update("Next game");
    link.onclick = function() { fetchGames(div, mode, "running", nextGame); } 
    $(div).insert(link);

    setTitle();
}

function nextGame(games, div, mode, status) {
    games.each(function(elem) {
        if (elem.action_required) { document.location = elem.link; }
    });
    showActiveGames(games, div, mode, status);
}

function loadOrSavePlan(save) {
    dataEntrySetStatus(true);

    var target = "/cgi-bin/plan.pl";
    target = "http://" + backendDomain + target;

    var form_params = {
        "cache-token": new Date() - Math.random(),
        "game": params.game,
        "faction-key": params.key,
        "preview-faction": currentFaction,
    };
    if (save) {
        form_params['set-note'] = $("planning_entry_input").value;
    }

    new Ajax.Request(target, {
        method: "get",
        parameters: form_params,
        onSuccess: function(transport){
            var notes = transport.responseText.evalJSON();
            $("planning_entry_input").value = notes.note;
            dataEntrySetStatus(false);
        }
    });
}

function loadPlan() {
    loadOrSavePlan(false);
}

function savePlan() {
    loadOrSavePlan(true);
}

var plan_loaded = 0;
function initPlanIfNeeded() {
    if (plan_loaded) {
        return;
    }
    loadPlan();
    plan_loaded = 1;
}
