var params = null;
var moveRequired = false;

function setTitle() {
    try {
        var title = "TM";
        if (params) {
            if (params.game) {
                title += " - " + params.game;
            }
            if (params.faction) {
                title += " / " + params.faction;
            }
        }
        if (moveRequired) {
            title = "*** " + title;
            setFavicon("/favicon.ico");
        } else {
            setFavicon("/favicon-inactive.ico");
        }
        document.title = title;
    } catch (e) {
    }
}

function setFavicon(url) {
    var icon = $("favicon");
    var new_icon = icon.cloneNode(true);
    new_icon.setAttribute('href', url);
    icon.parentNode.replaceChild(new_icon, icon);
}

function fetchGames(div, mode, status, handler) {
    $(div).update("... loading");
    new Ajax.Request("/cgi-bin/gamelist.pl", {
        parameters: { "mode": mode, "status": status },
        method:"get",
        onSuccess: function(transport){
            var resp = transport.responseText.evalJSON();
            try {
                if (!resp.error) {
                    handler(resp.games, div, mode, status);
                } else {
                    $(div).update(resp.error);
                }
            } catch (e) {
                handleException(e);
            };
        }
    });
}

