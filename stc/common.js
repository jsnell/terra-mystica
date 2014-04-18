var stored_exception = null;

function handleException (e) {
    stored_exception = e;
    var p = document.getElementById("error");
    p.innerHTML += e;
    if (console && console.trace) {
        console.trace(e);
    }
}

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
    if (!loggedIn()) {
        $(div).update("Not logged in (<a href='/login/'>login</a>)");
        return;
    }

    $(div).update("... loading");
    new Ajax.Request("/app/list-games/", {
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

function seconds_to_pretty_time(seconds) {
    var subamount = '';
    var amount;
    var unit;

    var hour = 3600;
    var day = 24*hour;
    var year = day*365;
    var month = day*30;

    if (seconds >= year) {
        amount = Math.floor(seconds / year);
        unit = "year";
        var remainder = (seconds - amount * year) % day;
        if (remainder >= month) {
            subamount = ' ' + seconds_to_pretty_time(remainder);
        }
    } else if (seconds >= month) {
        amount = Math.floor(seconds / month);
        unit = "month";
        var remainder = seconds - amount * month;
        if (remainder >= day) {
            subamount = ' ' + seconds_to_pretty_time(remainder);
        }
    } else if (seconds >= day) {
        amount = Math.floor(seconds / day);
        unit = "day";
    } else if (seconds >= hour) {
        amount = Math.floor(seconds / hour);
        unit = "hour";
    } else if (seconds > 60) {
        amount = Math.floor(seconds / 60);
        unit = "minute";
    } else {
        amount = Math.floor(seconds);
        unit = "second";
    }
    if (amount > 1) { unit += "s" }
    return amount + " " + unit + subamount;
}

function loggedIn() {
    return /session-username=([A-Za-z0-9]+)/.match(document.cookie)
}

function renderSidebar(id) {
    var p = new Element("p");
    var insertLink = function(link, text, accesskey) {
        if (document.location.pathname == link) {
            p.insert(new Element("span", { "class": "navi-selected" }).update(text));
        } else {
            p.insert(new Element("a", {"class": "navi",
                                       "href": link,
                                       "accesskey": accesskey}).update(text));
        }
        p.insert(new Element("br"));
    };

    insertLink("/", "Home", "h");
    if (!loggedIn()) {
        insertLink("/login/", "Login");
        insertLink("/register/request/", "Register");
        p.insert(new Element("br"));
    } else {
        insertLink("/joingame/", "Join Game");
        insertLink("/newgame/", "New Game");
        insertLink("/settings/", "Settings");
        insertLink("/app/logout/", "Logout");
    }
    p.insert(new Element("br"));
    insertLink("/stats/", "Statistics");
    insertLink("/ratings/", "Ratings");
    insertLink("/changes/", "Changes");
    insertLink("/about/", "About");
    insertLink("/usage/", "Help");

    $(id).insert(p);
}

function makeTextSpan(content, klass) {
    var attrs = klass ? { 'class': klass } : {};
    var elem = new Element('span', attrs);
    elem.updateText(content);
    return elem;
}

{
    Element.addMethods({
        updateText: function(element, text) {
            element.textContent = text;
            return element;
        },
        insertTextSpan: function(element, text, klass) {
            return element.insert(makeTextSpan(text, klass));
        },
        clearContent: function(element) {
            element.innerHTML = "";
        },
    });
}                      

var isMobile = {
    Android: function() {
        return navigator.userAgent.match(/Android/i);
    },
    BlackBerry: function() {
        return navigator.userAgent.match(/BlackBerry/i);
    },
    iOS: function() {
        return navigator.userAgent.match(/iPhone|iPod/i);
    },
    Opera: function() {
        return navigator.userAgent.match(/Opera Mini/i);
    },
    Windows: function() {
        return navigator.userAgent.match(/IEMobile/i);
    },
    any: function() {
        return (isMobile.Android() || isMobile.BlackBerry() || isMobile.iOS() || isMobile.Opera() || isMobile.Windows());
    }
};

// Colors

function setFactionStyleForElement(element, faction_name) {
    if (factionColor[faction_name]) {
        element.style.backgroundColor = bgcolors[factionColor[faction_name]];
        element.style.color = contrastColor[factionColor[faction_name]];
    }
}

function factionTableCell(faction_name) {
    var td = new Element("td").updateText(faction_name);
    setFactionStyleForElement(td, faction_name);
    return td;
}

var colors = {
    red: '#e04040',
    green: '#40a040',
    yellow: '#e0e040',
    brown: '#a06040',
    blue: '#2080f0',
    black: '#000000',
    white: '#ffffff',
    gray: '#808080',
    ice: '#f0f8ff',
    orange: '#f0c040',
    player: '#c0c0c0',
    activeUI: '#8f8'
};

var bgcolors = {
    red: '#f08080',
    green: '#80f080',
    yellow: '#f0f080',
    blue: '#60c0f0',
    black: '#404040',
    white: '#ffffff',
    gray: '#c0c0c0',
    brown: '#b08040',
    ice: '#e0f0ff',
    player: '#404040'
};

var contrastColor = {
    red: '#000',
    green: '#000',
    yellow: '#000',
    blue: '#000',
    black: '#c0c0c0',
    white: '#000',
    gray: '#000',
    brown: '#000',
    ice: '#000',
    player: '#000'
};

var factionColor = {
    chaosmagicians: 'red',
    giants: 'red',
    nomads: 'yellow',
    fakirs: 'yellow',
    halflings: 'brown',
    cultists: 'brown',
    alchemists: 'black',
    darklings: 'black',
    swarmlings: 'blue',
    mermaids: 'blue',
    witches: 'green',
    auren: 'green',
    dwarves: 'gray',
    engineers: 'gray',
    icemaidens: 'ice',
    yetis: 'ice',
};

