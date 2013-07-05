var state = null;

function setEntryStatus(disabled) {
    $("settings").descendants().each(function (elem) {
        elem.disabled = disabled;
    });
}

function loadOrSaveSettings(save) {
    var target = "/cgi-bin/settings.pl";

    var form_params = {
        "cache-token": new Date() - Math.random(),
    };
    if (save) {
        form_params['displayname'] = $("displayname").value;
        form_params['save'] = 1;
    }

    setEntryStatus(true);

    new Ajax.Request(target, {
        method: "post",
        parameters: form_params,
        onSuccess: function(transport){
            state = transport.responseText.evalJSON();
            setEntryStatus(false);
            if (state.link) {
                document.location = state.link;
            } else if (state.error.length) {
                $("error").innerHTML = state.error.join("<br>");
            } else {
                renderSettings(state);
            }
        }
    });
}

function loadSettings() {
    loadOrSaveSettings(false);
}

function saveSettings() {
    loadOrSaveSettings(true);
}

function renderSettings(state) {
    $("username").innerHTML = state.username;
    $("displayname").value = state.displayname;
    var newEmailList = new Element("ul");
    $H(state.email).each(function (elem) {
        newEmailList.insert(new Element("li").update(elem.key));
    });

    $("email").update(newEmailList);
}