var params = null;
var moveRequired = false;
var updateTitle = true;
var updateFavicon = true;

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
        if (updateTitle) {
            document.title = title;
        }
    } catch (e) {
    }
}

function setFavicon(url) {
    if (!updateFavicon) {
        return;
    }

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

function fetchChangelog(handler) {
    new Ajax.Request("/data/changes.json", {
        parameters: {
            "cache-token": new Date()
        },
        method: "get",
        onSuccess: function(transport){
            try {
                var resp = transport.responseText.evalJSON();
                if (!resp.error) {
                    handler(resp.changes);
                }
            } catch (e) {
                handleException(e);
            };
        }
    });
}

function showChangelog(data, div, heading, max_age) {
    data = data.select(function (record) {
        return (new Date() - new Date(record.date)) / 1000 < max_age;
    });

    if (data.size() > 0)  {
        div.insert(new Element("h4").update(heading));
    }

    data.each(function (record) {
        var e = new Element("div", {"class": "changelog-entry"});
        e.insert(new Element("b").update("#{date} - #{title}".interpolate(record)));
        e.insert(new Element("p").update(record.description));
        div.insert(e);
    });
}
