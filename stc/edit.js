function save() {
    $("save-button").disable();
    new Ajax.Request("/cgi-bin/save.pl", {
        method:"post",
        parameters: {
            "game": id,
            "content": editor.getValue(),
        },
        onFailure: function(transport) {
            try {
                $("save-button").enable();
            } catch (e) {
                handleException(e);
            };
        }, 
        onSuccess: function(transport) {
            try {
                $("save-button").enable();
            } catch (e) {
                handleException(e);
            };
        }
    });
}
