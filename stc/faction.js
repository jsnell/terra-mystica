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
                document.location.reload();
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