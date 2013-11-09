var state = null;

function loadOrSaveSettings(save) {
    var target = "/cgi-bin/settings.pl";

    var form_params = {
        "cache-token": new Date() - Math.random(),
        "csrf-token": getCSRFToken()
    };
    if (save) {
        form_params['displayname'] = $("displayname").value;
        form_params['email_notify_turn'] = $("email_notify_turn").checked;
        form_params['email_notify_all_moves'] = $("email_notify_all_moves").checked;
        form_params['email_notify_chat'] = $("email_notify_chat").checked;
        form_params['save'] = 1;
    }

    disableDescendants($("settings"));

    new Ajax.Request(target, {
        method: "post",
        parameters: form_params,
        onSuccess: function(transport){
            state = transport.responseText.evalJSON();
            enableDescendants($("settings"));
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
    newEmailList.insert(new Element("li").update(
        new Element("a", { "href": "/alias/"}).update(
            "Add new address")));

    $("email_notify_turn").checked = state.email_notify_turn;
    $("email_notify_all_moves").checked = state.email_notify_all_moves;
    $("email_notify_chat").checked = state.email_notify_chat;

    $("email").update(newEmailList);
}