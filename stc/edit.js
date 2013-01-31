var fallback = false;
var id = document.location.pathname;
var editor = null;

// From JQuery
var Browser = Class.create({
  initialize: function() {
    var userAgent = navigator.userAgent.toLowerCase();
    this.version = (userAgent.match( /.+(?:rv|it|ra|ie)[\/: ]([\d.]+)/ ) || [])[1];
    this.android = /android/.test( userAgent );
    this.ios = /iPhone|iPad|iPod/.test( userAgent );
    this.webkit = /webkit/.test( userAgent );
    this.opera = /opera/.test( userAgent );
    this.msie = /msie/.test( userAgent ) && !/opera/.test( userAgent );
    this.mozilla = /mozilla/.test( userAgent ) && !/(compatible|webkit)/.test( userAgent );
  }
});

var browser = new Browser();

function init() {
    if (browser.msie && browser.version < 9) {
        fallback = true;
    }
    if (browser.android || browser.ios) {
        fallback = true;
    }

    if (fallback) {
        $("wrapper").style.display = "none";
        $("fallback-editor").style.display = "block";
    } else {
        editor = ace.edit("editor");
        var hash;
        editor.getSession().setMode("ace/mode/sh");
        editor.commands.removeCommand("replace");
        editor.commands.removeCommand("gotoline");

        editor.commands.addCommand({
            name: 'mySave',
            bindKey: { win: 'Ctrl-S',  mac: 'Command-S' },
            exec: save
        });
    }

    load();
}

function getEditorContent() {
    if (editor) {
        return editor.getValue();
    } else {
        return $("fallback-editor").value;
    }
}

function setEditorContent(data) {
    if (editor) {
        editor.setValue(data);
        editor.clearSelection();
    } else {
        $("fallback-editor").value = data;
    }
}

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
            "content": getEditorContent(),
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
                drawActionRequired(res);
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
                setEditorContent(res.data);
                hash = res.hash;

                var title = getEditorContent().match("# (.*)");
                if (title && title[1]) {
                    $("title").innerHTML += " (" + title[1] + ")";
                    $("header").innerHTML += " (" + title[1] + ")";
                }

                drawActionRequired(res);
            } catch (e) {
                handleException(e);
            };
        }
    });
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
    orange: '#f0c040',
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
};

function coloredFactionSpan(state, faction_name) {
    record = {};
    record.bg = colors[state.factions[faction_name].color];
    record.fg = (record.bg == '#000000' ? '#ccc' : '#000');
    record.display = state.factions[faction_name].display;

    return "<span style='background-color:#{bg}; color: #{fg}'>#{display}</span>".interpolate(record);
}

function drawActionRequired(state) {
    if (!$("action_required")) {
        return;
    }

    $("action_required").innerHTML = '';

    state.action_required.each(function(record) {
        if (record.type == 'full') {
            record.pretty = 'should take an action';
        } else if (record.type == 'leech') {
            record.from_faction_span = coloredFactionSpan(state, record.from_faction);
            record.pretty = 'may gain #{amount} power from #{from_faction_span}'.interpolate(record);
        } else if (record.type == 'transform') {
            if (record.amount == 1) {
                record.pretty = 'may use a shovel'.interpolate(record);
            } else {
                record.pretty = 'may use #{amount} shovels'.interpolate(record);
            }
        } else if (record.type == 'cult') {
            if (record.amount == 1) {
                record.pretty = 'may advance 1 step on a cult track'.interpolate(record);
            } else {
                record.pretty = 'may advance #{amount} steps on cult tracks'.interpolate(record);
            }
        } else if (record.type == 'town') {
            if (record.amount == 1) {
                record.pretty = 'may form a town'.interpolate(record);
            } else {
                record.pretty = 'may form #{amount} towns'.interpolate(record);
            }
        } else if (record.type == 'favor') {
            if (record.amount == 1) {
                record.pretty = 'may take a favor tile'.interpolate(record);
            } else {
                record.pretty = 'may take #{amount} favor tiles'.interpolate(record);
            }
        } else {
            record.pretty = '?';
        }

        record.faction_span = coloredFactionSpan(state, record.faction);

        var row = new Element("div", {'style': 'margin: 3px'}).update("#{faction_span} #{pretty}</div>".interpolate(record));
        $("action_required").insert(row);
    });
}
