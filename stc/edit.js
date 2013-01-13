function save() {
    if ($("save-button").disabled) {
        return;
    }

    $("error").update("");
    $("save-button").disable();
    new Ajax.Request("/cgi-bin/save.pl", {
        method:"post",
        parameters: {
            "game": id,
            "content": editor.getValue(),
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
                $("save-button").enable();
            } catch (e) {
                handleException(e);
            };
        }
    });
}
