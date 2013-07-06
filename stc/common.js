var params = null;
var moveRequired = false;

function disableDescendants(parent) {
    parent.descendants().each(function (elem) {
        elem.disabled = true;
    });
}

function enableDescendants(parent) {
    parent.descendants().each(function (elem) {
        elem.disabled = false;
    });
}

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

function getCSRFToken() {
    var match = document.cookie.match(/csrf-token=([^ ;]+)/);
    if (match) {
        return match[1];
    } else {
        return "invalid";
    }
}

function fetchGames(div, mode, status, handler, args) {
    $(div).update("... loading");
    new Ajax.Request("/cgi-bin/gamelist.pl", {
        parameters: {
            "mode": mode,
            "status": status,
            "args": args,
            "csrf-token": getCSRFToken()
        },
        method:"post",
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

