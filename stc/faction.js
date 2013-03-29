var state = null;
var params = null;
var currentFaction = null;
var backendDomain = null;

function loadGame (domain, pathname) {
    var path = pathname.sub("/faction/", "").split("/");
    backendDomain = domain;
    state = null;
    params = { "game": path[0], "faction": path[1], "key": path[2] };
    
    if ($("title")) {
        $("title").text += " - " + params.game + " / " + params.faction;
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
    new Ajax.Request(target, {
        method: "get",
        parameters: {
            "game": params.game,
            "preview": preview,
            "faction-key": params.key,
            "preview-faction": currentFaction
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
    var status = $(preview_status).innerHTML;
    var moves = $(preview_commands).textContent.split(/\n/).map(function (x) {
        return "  " + encodeURIComponent(x);
    }).join(newline);
    var actions = $(action_required).childElements().map(function (x) {
        return "  " + encodeURIComponent(x.textContent);
    }).join(newline)
    var footer = "Round #{round}, turn #{turn}".interpolate(state);

    var moves = status + ":" + newline + moves + newline + newline + "Actions required:" + newline + actions + newline + newline + footer;

    var link = "mailto:" + encodeURIComponent(state.email) + "?subject=Re: Terra Mystica PBEM (" + params.game + ")&body=" + moves;

    return link;
}


