function viewMap(mapid) {
    var target = "/app/map/view/" + mapid;
    forbidSave();

    new Ajax.Request(target, {
        method: "post",
        parameters: {
            "cache-token": new Date() - Math.random(),            
        },
        onSuccess: function(transport) {
            state = transport.responseText.evalJSON();

            if (state.error.length) {
                $("map").hide();
                $("error").innerHTML = state.error.join("<br>");
            } else {
                $("map").show();
                updateMapId(state.mapid, true);
                drawMap();
                $("map-data").value = state.mapdata;
            }
        }
    });
}

function previewMap() {
    var target = "/app/map/preview/";
    forbidSave();

    new Ajax.Request(target, {
        method: "post",
        parameters: {
            "cache-token": new Date() - Math.random(),
            "map-data": $("map-data").value,
        },
        onSuccess: function(transport){
            state = transport.responseText.evalJSON();

            if (state.error.length) {
                $("map").hide();
                $("error").innerHTML = state.error.join("<br>");
            } else {
                $("map").show();
                updateMapId(state.mapid, state.saved);
                drawMap();
                $("map-data").value = state.mapdata;
                allowSave();
            }
        }
    });
}

function saveMap(mapid) {
    var target = "/app/map/save/";
    forbidSave();

    new Ajax.Request(target, {
        method: "post",
        parameters: {
            "cache-token": new Date() - Math.random(),
            "map-data": $("map-data").value,
        },
        onSuccess: function(transport) {
            $("map").show();
            state = transport.responseText.evalJSON();

            if (state.error.length) {
                $("error").innerHTML = state.error.join("<br>");
            } else {
                document.location = "/map/" + state.mapid;
            }
        }
    });
}

function allowSave() {
    $("save").disabled = false;
}

function forbidSave() {
    $("save").disabled = true;
}

function updateMapId(id, saved) {
    var elem = null;

    if (saved) {
        elem = new Element("a", { "href": "/map/" + id}).updateText(id);
    } else {
        elem = new Element("span").updateText(id);
    }

    $("map-id").updateText("");
    $("map-id").insert(elem);
}

function showMap() {
    var mapid = document.location.pathname.sub(/\/map\//, '');
    if (mapid) {
        viewMap(mapid);
    }
}
