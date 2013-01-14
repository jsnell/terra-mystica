function save() {
    if ($("save-button").disabled) {
        return;
    }

    $("error").update("");
    $("save-button").disable();
    new Ajax.Request("/cgi-bin/save.pl", {
        method: "post",
        parameters: {
            "game": id,
            "content": editor.getValue(),
            "orig-hash": hash,
        },
        onFailure: function(transport) {
            $("error").innerHTML = "Error saving game.";
            try {
                $("save-button").enable();
            } catch (e) {
                handleException(e);
            };
        }, 
        onSuccess: function(transport) {
            try {
                var res = transport.responseText.evalJSON();
                res.error.each(function(line) {
                    $("error").insert(line.escapeHTML() + "<br>");
                });
                if (res.error.size() == 0) {
                    hash = res.hash;
                }
                $("save-button").enable();
            } catch (e) {
                handleException(e);
            };
        }
    });
}

function load() {
    new Ajax.Request("/cgi-bin/edit.pl?game=" + id, {
        method:"get",
        onFailure: function(transport) {
            $("error").innerHTML = "Error opening game."
            $("save-button").disable();             
        },
        onSuccess: function(transport){
            try {
                var res = transport.responseText.evalJSON();
                editor.setValue(res.data);
                editor.clearSelection();
                hash = res.hash;

                var title = editor.getValue().match("# (.*)");
                if (title && title[1]) {
                    $("title").innerHTML += " (" + title[1] + ")";
                    $("header").innerHTML += " (" + title[1] + ")";
                }
            } catch (e) {
                handleException(e);
            };
        }
    });
}
