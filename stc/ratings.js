var state = null;
var id = document.location.pathname;

function showRatings(kind) {
    var table = $(kind + "-ratings");

    var header = new Element("tr");
    if (kind == "player") {
        header.insert(new Element("td").updateText("Rank"));
    }
    header.insert(new Element("td").updateText("Rating"));
    header.insert(new Element("td").updateText("Name"));
    header.insert(new Element("td").updateText("Games Played"));
    if (kind == "player") {
        header.insert(new Element("td").updateText("Breakdown"));
    }
    table.insert(header);

    var rank = 1;

    $H(state[kind + "s"]).sortBy(function (a) { return -a.value.score } ).each(function(elem) {
        var value = elem.value;
        var row = new Element("tr");
        if (kind == "player") {
            if (rank == 1 || rank % 10 == 0) {
                row.insert(new Element("td").updateText(rank));
            } else {
                row.insert(new Element("td"));
            }
            rank++;
        }
        row.insert(new Element("td").updateText(Math.floor(value.score)));
        if (kind == "player") {
            row.insert(new Element("td").update(
                new Element("a", {"href":"/player/" + value.username}).
                    updateText(value.username)));
            row.insert(new Element("td").updateText(value.games));
            var breakdown = new Element("table", {
                "class": "ranking-breakdown-table",
            });
            breakdown.insert(new Element("tr").insert(
                new Element("td").updateText("Faction")).insert(
                    new Element("td").updateText("Delta")).insert(
                        new Element("td").updateText("Plays")));
                    
            $H(value.faction_breakdown).sortBy(function (elem) { return -elem.value.score }).each(function (elem) {
                var breakdown_row = new Element("tr");
                breakdown_row.insert(factionTableCell(elem.key));
                breakdown_row.insert(new Element("td").updateText(Math.round(elem.value.score)));
                breakdown_row.insert(new Element("td").updateText(Math.round(elem.value.count)));
                breakdown.insert(breakdown_row);
            });
            breakdown.hide();
            var cell = new Element("td");
            var show = new Element("a", { href: "javascript:" }).updateText("show");
            show.onclick = function() { show.hide(); breakdown.show(); };
            cell.insert(show);
            cell.insert(breakdown);
            row.insert(cell);
        } else {
            row.insert(factionTableCell(value.name));
            row.insert(new Element("td").updateText(value.games));
        }
        table.insert(row);
    });
}

function showLinks(id) {
    $(id + "-links").style.display = "block";
    $(id + "-show-link").style.display = "none";
}

function loadRatings() {
    new Ajax.Request("/data/ratings.json", {
        method:"get",
        onSuccess: function(transport){
            state = transport.responseText.evalJSON();
            try {
                showRatings("player");
                showRatings("faction");
                $("timestamp").innerHTML = "Last updated: " + state.timestamp;
            } catch (e) {
                handleException(e);
            };
        }
    });
}
