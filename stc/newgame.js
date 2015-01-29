var state = null;

function newGameValidate() {
    var disabled = false;
    var okColor = "#fff";
    var badColor = "#faa";
    var validateHighlights = {
        "option-email-notify-label": okColor,
        "option-maintain-player-order-label": okColor,
        "player-count": okColor,
        "players": okColor,
        "gameid": okColor,
        "game-type": okColor,
        "label-option-fire-and-ice-factions/variable": okColor,
    }

    if ($("gameid").value == "" ||
        $("gameid").value.length > 32) {
        disabled = true;
        validateHighlights["gameid"] = badColor;
    }
    if ($("game-type").value == "-") {
        disabled = true;
        validateHighlights["game-type"] = badColor;
        $("players-row").hide();
        $("description-row").hide();
        $("player-count-row").hide();
        $("rating-row").hide();
    } else if ($("game-type").value == "public") {
        $("players-row").hide();
        $("description-row").show();
        $("player-count-row").show();
        $("rating-row").show();
        if (!$("option-email-notify").checked) {
            disabled = true;
            validateHighlights["option-email-notify-label"] = badColor;
        }
        if ($("option-maintain-player-order").checked) {
            disabled = true;
            validateHighlights["option-maintain-player-order-label"] = badColor;
        }
        if ($("player-count").value == "-") {
            disabled = true;
            validateHighlights["player-count"] = badColor;
        }
    } else if ($("game-type").value == "private") {
        $("players-row").show();
        $("description-row").hide();
        $("player-count-row").hide();
        $("rating-row").hide();
        var players = $("players").value.gsub(/^\s+|\s+$/, '').split(/\n/);
        
        if (players.size() < 2) {
            disabled = true;
            validateHighlights["players"] = badColor;
        }
    }

    ['ice', 'variable', 'variable_v2', 'volcano'].each(function (type) {
        $("option-fire-and-ice-factions/" + type).disabled =
            !$("option-fire-and-ice-factions").checked;
    });

    if ($("option-fire-and-ice-factions/variable").checked &&
        $("option-fire-and-ice-factions/variable_v2").checked) {
        disabled = true;
        validateHighlights["label-option-fire-and-ice-factions/variable"] = badColor;        
    }

    $H(validateHighlights).each(function (elem) {
        $(elem.key).style.backgroundColor = elem.value;
    });

    if (disabled) {
        $("new-game-disabled").show();
    } else {
        $("new-game-disabled").hide();
    }

    $("submit").disabled = disabled;
}

function newGame() {
    $("error").innerHTML = "";
    $("csrf-token").value = getCSRFToken();
    disableDescendants($("submit"));
    $("newgame").request({
        method:"post",
        onSuccess: function(transport) {
            state = transport.responseText.evalJSON();
            enableDescendants($("submit"));
            if (state.link) {
                document.location = state.link;
            } else if (state.error.length) {
                $("error").innerHTML = state.error.join("<br>");
            }
        }
    });    
}
