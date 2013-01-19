var fallback = false;
var id = document.location.pathname;
var editor = null;

// From JQuery
var Browser = Class.create({
  initialize: function() {
    var userAgent = navigator.userAgent.toLowerCase();
    this.version = (userAgent.match( /.+(?:rv|it|ra|ie)[\/: ]([\d.]+)/ ) || [])[1];
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
            } catch (e) {
                handleException(e);
            };
        }
    });
}
