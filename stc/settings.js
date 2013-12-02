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
        try {
            form_params['primary_email'] = $$(".primary-email-radio:checked")[0].value;
        } catch (e) {
        }
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
    var newEmailList = new Element("div");
    var first = true;
    $H(state.email).each(function (elem) {
        var row = new Element("div");
        var radio = new Element("input", { "type": "radio",
                                           "class": "primary-email-radio",
                                           "name": "primary_email",
                                           "id": "primary_email_" + elem.key,
                                           "checked": first || elem.value.is_primary,
                                           "value": elem.key })
        var label = new Element("label",
                                { "for": "primary_email_" + elem.key }).update(elem.key);
        row.insert(radio);
        row.insert(label);
        newEmailList.insert(row);
        first = false;
    });
    newEmailList.insert(new Element("div").update(
        new Element("a", { "href": "/alias/"}).update(
            "Add new address")));

    $("email_notify_turn").checked = state.email_notify_turn;
    $("email_notify_all_moves").checked = state.email_notify_all_moves;
    $("email_notify_chat").checked = state.email_notify_chat;

    $("email").update(newEmailList);
}