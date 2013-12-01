var hex_size = 35;
var hex_width = (Math.cos(Math.PI / 6) * hex_size * 2);
var hex_height = Math.sin(Math.PI / 6) * hex_size + hex_size;

function hexCenter(row, col) {
    var x_offset = row % 2 ? hex_width / 2 : 0;
    var x = 5 + hex_size + col * hex_width + x_offset,
        y = 5 + hex_size + row * hex_height;
    return [x, y];
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
    orange: '#f0c040'
};

var bgcolors = {
    red: '#f08080',
    green: '#80f080',
    yellow: '#f0f080',
    blue: '#60c0f0',
    black: '#404040',
    white: '#ffffff',
    gray: '#c0c0c0',
    brown: '#b08040'
};

var cult_bgcolor = {
    FIRE: "#f88",
    WATER: "#ccf",
    EARTH: "#b84",
    AIR: "#f0f0f0"
};

function drawText(ctx, text, x, y, font) {
    ctx.save();
    ctx.fillStyle = ctx.strokeStyle;
    ctx.lineWidth = 0.1;
    ctx.font = font;
    ctx.fillText(text, x, y);
    ctx.strokeText(text, x, y);            
    ctx.restore();    
}

function makeHexPath(ctx, x, y, size) {
    var angle = 0;
    
    ctx.beginPath();
    ctx.moveTo(x, y);
    for (var i = 0; i < 6; i++) {
        ctx.lineTo(x, y); 
        angle += Math.PI / 3;
        x += Math.sin(angle) * size;
        y += Math.cos(angle) * size;        
    }
    ctx.closePath();
}

function makeMapHexPath(ctx, hex, size) {
    size = size || hex_size;
    var loc = hexCenter(hex.row, hex.col);
    var x = loc[0] - Math.cos(Math.PI / 6) * size;
    var y = loc[1] + Math.sin(Math.PI / 6) * size;
    makeHexPath(ctx, x, y, size);
}

function fillBuilding(ctx, hex) {
    ctx.fillStyle = colors[hex.color];
    ctx.fill();

    if (hex.color == "black") {
        ctx.strokeStyle = '#808080';
    } else {
        ctx.strokeStyle = '#000';
    }
    ctx.lineWidth = 2;
    ctx.stroke();
}

function drawDwelling(ctx, hex) {
    var loc = hexCenter(hex.row, hex.col);

    ctx.save();

    ctx.beginPath();
    ctx.moveTo(loc[0], loc[1] - 10);
    ctx.lineTo(loc[0] + 10, loc[1]);
    ctx.lineTo(loc[0] + 10, loc[1] + 10);
    ctx.lineTo(loc[0] - 10, loc[1] + 10);
    ctx.lineTo(loc[0] - 10, loc[1]);
    ctx.closePath();

    fillBuilding(ctx, hex);

    ctx.restore();
}

function drawTradingPost(ctx, hex) {
    var loc = hexCenter(hex.row, hex.col);

    ctx.save();

    ctx.beginPath();
    ctx.moveTo(loc[0], loc[1] - 20);
    ctx.lineTo(loc[0] + 10, loc[1] - 10);
    ctx.lineTo(loc[0] + 10, loc[1] - 3);
    ctx.lineTo(loc[0] + 20, loc[1] - 3);
    ctx.lineTo(loc[0] + 20, loc[1] + 10);
    ctx.lineTo(loc[0] - 10, loc[1] + 10);
    ctx.lineTo(loc[0] - 10, loc[1]);
    ctx.lineTo(loc[0] - 10, loc[1] - 10);
    ctx.closePath();

    fillBuilding(ctx, hex);

    ctx.restore();
}

function drawTemple(ctx, hex) {
    var loc = hexCenter(hex.row, hex.col);
    loc[1] -= 5;

    ctx.save();

    ctx.beginPath();
    ctx.arc(loc[0], loc[1], 14, 0.001, Math.PI*2, false);

    fillBuilding(ctx, hex);

    ctx.restore();
}


function drawStronghold(ctx, hex) {
    var loc = hexCenter(hex.row, hex.col);
    loc[1] -= 5;
    var size = 15;
    var bend = 10;

    ctx.save();

    ctx.beginPath();
    ctx.moveTo(loc[0] - size, loc[1] - size);
    ctx.quadraticCurveTo(loc[0] - bend, loc[1],
                         loc[0] - size, loc[1] + size);
    ctx.quadraticCurveTo(loc[0], loc[1] + bend,
                         loc[0] + size, loc[1] + size);
    ctx.quadraticCurveTo(loc[0] + bend, loc[1],
                         loc[0] + size, loc[1] - size);
    ctx.quadraticCurveTo(loc[0], loc[1] - bend,
                         loc[0] - size, loc[1] - size);

    fillBuilding(ctx, hex);

    ctx.restore();
}

function drawSanctuary(ctx, hex) {
    var loc = hexCenter(hex.row, hex.col);
    var size = 7;
    loc[1] -= 5;

    ctx.save();

    ctx.beginPath();
    ctx.arc(loc[0] - size, loc[1], 12, Math.PI / 2, -Math.PI / 2, false);
    ctx.arc(loc[0] + size, loc[1], 12, -Math.PI / 2, Math.PI / 2, false);
    ctx.closePath();
    
    fillBuilding(ctx, hex);

    ctx.restore();
}

function drawHex(ctx, elem) {
    if (elem == null) {
        return;
    }

    var hex = elem.value;
    var id = elem.key;

    if (hex.row == null) {
        return;
    }

    var loc = hexCenter(hex.row, hex.col);

    if (hex.color == 'white') {
        if (hex.town || hex.possible_town) {
            var loc = hexCenter(hex.row, hex.col);
            ctx.save();
            var scale = hex.town ? 2 : 2.5;
            makeMapHexPath(ctx, hex, hex_size / scale);

            if (hex.town) {
                ctx.fillStyle = "#def";
                ctx.fill();

                ctx.strokeStyle = "#456";
            } else {
                ctx.strokeStyle = "#bbb";
            }
            ctx.lineWidth = 2;
            ctx.stroke();

            ctx.restore();
        }

        if (hex.possible_town) {
            drawText(ctx, id, loc[0] - 9, loc[1] + 25,
                     "12px Verdana");
        }

        return;
    }

    makeMapHexPath(ctx, hex);

    ctx.save();
    ctx.fillStyle = bgcolors[hex.color];
    ctx.fill();
    ctx.restore();

    ctx.save();
    ctx.strokeStyle = "#000000";
    ctx.lineWidth = 2;
    makeMapHexPath(ctx, hex);
    ctx.stroke();
    ctx.restore();

    if (hex.building == 'D') {
        drawDwelling(ctx, hex);
    } else if (hex.building == 'TP' || hex.building == 'TH') {
        drawTradingPost(ctx, hex);
    } else if (hex.building == 'TE') {
        drawTemple(ctx, hex);
    } else if (hex.building == 'SH') {
        drawStronghold(ctx, hex);
    } else if (hex.building == 'SA') {
        drawSanctuary(ctx, hex);
    }

    ctx.save();
    if (hex.color == "black") {
        ctx.strokeStyle = "#c0c0c0";
    } else {
        ctx.strokeStyle = "#000";
    }
    drawText(ctx, id, loc[0] - 9, loc[1] + 25,
             hex.town ? "bold 12px Verdana" : "12px Verdana");
    ctx.restore();
}

function drawBridge(ctx, from, to, color) {
    var from_loc = hexCenter(state.map[from].row, state.map[from].col);
    var to_loc = hexCenter(state.map[to].row, state.map[to].col);

    ctx.save();

    ctx.beginPath();
    ctx.moveTo(from_loc[0], from_loc[1]);
    ctx.lineTo(to_loc[0], to_loc[1]);

    ctx.strokeStyle = '#222';
    ctx.lineWidth = 10;
    ctx.stroke();
    
    ctx.strokeStyle = colors[color];
    ctx.lineWidth = 8;
    ctx.stroke();

    ctx.restore();
}

function drawMap() {
    var canvas = $("map");
    if (canvas.getContext) {
        canvas.width = canvas.width;
        var ctx = canvas.getContext("2d");

        state.bridges.each(function(bridge, index) {
            drawBridge(ctx, bridge.from, bridge.to, bridge.color);
        });

        $H(state.map).each(function(hex, index) { drawHex(ctx, hex) });
    }
}

function hexClickHandler(fun) {
    return function (event) {
        var position = $("map").getBoundingClientRect();
        var x = event.clientX - position.left;
        var y = event.clientY - position.top;
        var best_dist = null;
        var best_loc = null;
        for (var r = 0; r < 9; ++r) {
            for (var c = 0; c < 13; ++c) {
                var center = hexCenter(r, c);
                var xd = (x - center[0]);
                var yd = (y - center[1]);
                var dist = xd*xd + yd*yd;
                if (best_dist == null || dist < best_dist) {
                    best_loc = [r, c];
                    best_dist = dist;
                }
            }
        }
        var hex_id = null;
        $H(state.map).each(function(elem) {
            var hex = elem.value;
            if (hex.row == best_loc[0] &&
                hex.col == best_loc[1]) {
                hex_id = elem.key;
            }
        });
        if (hex_id != null && fun != null) {
            fun(hex_id);
        }
    };
}

var cults = ["FIRE", "WATER", "EARTH", "AIR"];

function drawCults() {
    var canvas = $("cults");
    if (canvas.getContext) {
        canvas.width = canvas.width;
        var ctx = canvas.getContext("2d");

        var x_offset = 0;

        var width = 250 / 4;
        var height = 500;

        for (var j = 0; j < 4; ++j) {
            var cult = cults[j];

            ctx.save();

            ctx.translate(width * j, 0);

            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(0, height);
            ctx.lineTo(width, height);
            ctx.lineTo(width, 0);
            ctx.closePath();
            ctx.fillStyle = cult_bgcolor[cult];
            ctx.fill();

            drawText(ctx, cult, 5, 15, "15px Verdana");

            ctx.translate(0, 20);

            var seen10 = false;

            for (var i = 10; i >= 0; --i) {
                ctx.save();
                ctx.translate(0, ((10 - i) * 40 + 20));

                drawText(ctx, i, 5, 0, "15px Verdana");

                state.order.each(function(name, index) {
                    var faction = state.factions[name];
                    if (faction[cult] != i) {
                        return;
                    }

                    ctx.translate(12, 0);

                    drawCultMarker(ctx, faction.color, name,
                                   !seen10 && (i == 10 || faction.KEY > 0));
                    if (i == 10) {
                        seen10 = true;
                    }
                });

                ctx.restore();
            }

            ctx.save();
            ctx.translate(5, 470);
            ctx.font = "15px Verdana";
            ctx.lineWidth = 0.2;

            for (var i = 1; i < 5; ++i) {
                var text = (i == 1 ? 3 : 2);
                ctx.fillStyle = "#000";
                ctx.strokeStyle = "#000";

                var slot = state.map[cult + i];

                if (slot.building) {
                    text = "p";
                    ctx.fillStyle = colors[slot.color];
                    ctx.strokeStyle = colors[slot.color];
                }
                ctx.fillText(text, 0, 0);
                ctx.strokeText(text, 0, 0);

                ctx.translate(12, 0);
            }
            ctx.restore();

            ctx.restore();
        };

        ctx.save();
        ctx.beginPath();
        ctx.strokeStyle = "#000";
        ctx.lineWidth = 1;
        ctx.translate(0, 60.5);
        ctx.moveTo(0, 0); ctx.lineTo(250, 0);
        ctx.moveTo(0, 3); ctx.lineTo(250, 3);
        ctx.moveTo(0, 6); ctx.lineTo(250, 6);

        ctx.translate(0, 120);
        ctx.moveTo(0, 0); ctx.lineTo(250, 0);
        ctx.moveTo(0, 3); ctx.lineTo(250, 3);

        ctx.translate(0, 80);
        ctx.moveTo(0, 0); ctx.lineTo(250, 0);
        ctx.moveTo(0, 3); ctx.lineTo(250, 3);

        ctx.translate(0, 80);
        ctx.moveTo(0, 0); ctx.lineTo(250, 0);

        ctx.stroke();
        ctx.restore();
    }
}

function drawCultMarker(ctx, color, name, hex) {
    ctx.save();
    ctx.beginPath();

    if (hex) {
        strokeCultMarkerHex(ctx);
    } else {
        strokeCultMarkerArc(ctx);
    }

    ctx.fillStyle = colors[color];
    ctx.fill();
    ctx.stroke()
    ctx.restore();

    ctx.save();
    ctx.strokeStyle = (color == 'black' ? '#ccc' : '#000');
    ctx.textAlign = 'center';
    var l = name[0].toUpperCase();
    if (name == 'cultists') { l  = 'c' }
    drawText(ctx, l, -2, 14,
             "bold 10px Verdana");
    ctx.restore();
}

function strokeCultMarkerArc(ctx) {
    ctx.arc(0, 10, 8, 0.001, Math.PI * 2, false);
}

function strokeCultMarkerHex(ctx) {
    ctx.save();
    makeHexPath(ctx, -8, 14, 8.5);
    ctx.restore();
}

function renderAction(canvas, name, key) {
    if (!canvas.getContext) {
        return;
    }

    var ctx = canvas.getContext("2d");

    ctx.save();
    ctx.translate(2, 2);

    if (state.map[key] && state.map[key].blocked) {
        ctx.fillStyle = '#ccc';
    } else {
        ctx.fillStyle = colors.orange;
    }
    ctx.strokeStyle = '#000';
    ctx.lineWidth = 2;

    ctx.translate(0.5, 0.5);
    ctx.moveTo(0, 10);
    ctx.lineTo(10, 0);
    ctx.lineTo(20, 0);
    ctx.lineTo(30, 10);
    ctx.lineTo(30, 20);
    ctx.lineTo(20, 30);
    ctx.lineTo(10, 30);
    ctx.lineTo(0, 20);
    ctx.lineTo(0, 10);
    ctx.closePath();

    ctx.fill();
    ctx.stroke();

    if (!name.startsWith("FAV") && !name.startsWith("BON")) {
        drawText(ctx, name, 1, 45, "10px Verdana");
    }

    ctx.save();
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    var data = {
        "ACT1": function() {
            drawText(ctx, "br", 15, 15, "10px Verdana");
            drawText(ctx, "-3PW", 15, 55, "10px Verdana");
        },
        "ACT2": function() {
            drawText(ctx, "P", 15, 15, "10px Verdana");
            drawText(ctx, "-3PW", 15, 55, "10px Verdana");
        },
        "ACT3": function() {
            drawText(ctx, "2W", 15, 15, "10px Verdana");
            drawText(ctx, "-4PW", 15, 55, "10px Verdana");
        },
        "ACT4": function() {
            drawText(ctx, "7C", 15, 15, "10px Verdana");
            drawText(ctx, "-4PW", 15, 55, "10px Verdana");
        },
        "ACT5": function() {
            drawText(ctx, "spd", 15, 15, "10px Verdana");
            drawText(ctx, "-4PW", 15, 55, "10px Verdana");
        },
        "ACT6": function() {
            drawText(ctx, "2 spd", 15, 15, "10px Verdana");
            drawText(ctx, "-6PW", 15, 55, "10px Verdana");
        },
        "ACTA": function() {
            drawText(ctx, "2cult", 15, 15, "10px Verdana");
        },
        "ACTN": function() {
            drawText(ctx, "tf", 15, 15, "10px Verdana");
        },
        "ACTS": function() {
            drawText(ctx, "TP", 15, 15, "10px Verdana");
        },
        "ACTW": function() {
            drawText(ctx, "D", 15, 15, "10px Verdana");
        },
        "BON1": function() {
            drawText(ctx, "spd", 15, 15, "10px Verdana");
        },
        "BON2": function() {
            drawText(ctx, "cult", 15, 15, "10px Verdana");
        },
        "FAV6": function() {
            drawText(ctx, "cult", 15, 15, "10px Verdana");
        }
    };

    if (data[name]) {
        data[name]();
    }

    ctx.restore();

    ctx.restore();
}

function cultStyle(name) {
    if (cult_bgcolor[name]) {
        return "style='background-color:" + cult_bgcolor[name] + "'";
    }

    return "";
}

function insertAction(parent, name, key) {
    parent.insert(new Element('canvas', {
        'class': 'action', 'width': 40, 'height': 80}));
    var canvas = parent.childElements().last();
    renderAction(canvas, name, key);
}

function renderTile(div, name, record, faction, count) {
    div.insert(name);
    if (state.map[name] && state.map[name].C) {
        div.insert(" [#{C}c]".interpolate(state.map[name]));
    }
    if (count > 1) {
        div.insert("(x" + count + ")");
    }
    div.insert("<hr>");

    if (!record) {
        return;
    }

    $H(record.gain).each(function (elem, index) {
        elem.style = cultStyle(elem.key);
        div.insert("<div><span #{style}>#{value} #{key}</span></div>".interpolate(elem));
    });
    $H(record.vp).each(function (elem, index) {
        div.insert("<div>#{key} &gt;&gt; #{value} vp</div>".interpolate(elem));
    });
    $H(record.pass_vp).each(function (elem, index) {
        var stride = elem.value[1] - elem.value[0];
        for (var i = 1; i < elem.value.length; ++i) {
            if (elem.value[i-1] + stride != elem.value[i]) {
                stride = null;
                break;
            }
        }

        if (stride) {
            elem.value = "*" + stride;
        } else {
            elem.value = " [" + elem.value + "]";
        }

        div.insert("<div>pass-vp:#{key}#{value}</div>".interpolate(elem));
    });
    if (record.action) {
        insertAction(div, name, name + "/" + faction);
    }
    $H(record.income).each(function (elem, index) {
        div.insert("<div>+#{value} #{key}</div>".interpolate(elem));
    });
    $H(record.special).each(function (elem, index) {
        div.insert("<div>#{value} #{key}</div>".interpolate(elem));
    });
}

function renderBonus(div, name, faction) {
    renderTile(div, name, state.bonus_tiles[name], faction, 1);
}

function renderFavor(div, name, faction, count) {
    renderTile(div, name, state.favors[name], faction, count);
}

function renderTown(div, name, faction, count) {
    if (count != 1) {
        div.insert(name + " (x" + count + ")");
    } else {
        div.insert(name);
    }

    var head = "#{VP} vp".interpolate(state.towns[name].gain);
    if (state.towns[name].gain.KEY != 1) {
        head += ", #{KEY} keys".interpolate(state.towns[name].gain);
    } 
    div.insert(new Element("div").update(head));
    $H(state.towns[name].gain).each(function(elem, index) {
        var key = elem.key;
        var value = elem.value;
        elem.style = cultStyle(key);

        if (key != "VP" && key != "KEY") {
            div.insert("<div><span #{style}>#{value} #{key}</span></div>".interpolate(elem));
        }
    });
}

function naturalSortKey(val) {
    var components = val.key.match(/(\d+|\D+)/g);
    var key = [];

    components.each(function(elem) {
        if (elem.match(/\d/)) {
            key.push(parseInt(elem) + 1e6);
        } else {
            key.push(elem);
        }
    });

    return key;
}

function renderTreasuryTile(board, faction, name, count) {
    if (count < 1) {
        return;
    }

    if (name.startsWith("ACT")) {
        insertAction(board, name, name);
        return;
    } else if (name.startsWith("BON")) {
        board.insert(new Element('div', {
            'class': 'bonus'}));
        var div = board.childElements().last();
        renderBonus(div, name, faction);            
    } else if (name.startsWith("FAV")) {
        board.insert(new Element('div', {
            'class': 'favor'}));
        var div = board.childElements().last();
        renderFavor(div, name, faction, count);
        return;
    } else if (name.startsWith("TW")) {
        board.insert(new Element('div', {
            'class': 'town'}));
        var div = board.childElements().last();
        renderTown(div, name, faction, count);
        return;
    }
}


function renderTreasury(board, treasury, faction) {
    $H(treasury).sortBy(naturalSortKey).each(function(elem, index) {
        var name = elem.key;
        var value = elem.value;

        renderTreasuryTile(board, faction, name, value);
    });
}

function makeBoard(color, name, klass, style) {
    var board = new Element('div', {
        'class': klass,
        'style': style
    });
    board.insert(new Element('div', {
        'style': 'padding: 1px 1px 1px 5px; background-color: ' + colors[color] + '; color: ' +
            (color == 'black' ? '#ccc' : '#000')
    }).update(name));

    return board;
}

var cycle = [ "red", "yellow", "brown", "black", "blue", "green", "gray" ]; 

function renderColorCycle(parent, startColor) {
    parent.insert(new Element('canvas', {
        'class': 'colorcycle', 'width': 80, 'height': 80}));
    var canvas = parent.childElements().last();

    if (!canvas.getContext) {
        return;
    }

    var ctx = canvas.getContext("2d");

    ctx.save()
    ctx.translate(40, 41);

    var base = cycle.indexOf(startColor);

    for (var i = 0; i < 7; ++i) {
        ctx.save()
        ctx.beginPath();
        ctx.arc(0, -30, 10, Math.PI * 2, 0, false);

        ctx.fillStyle = bgcolors[cycle[(base + i) % 7]];
        ctx.fill();
    
        ctx.stroke();
        ctx.restore();
        ctx.rotate(Math.PI * 2 / 7);
    }

    ctx.restore();
}

function rowFromArray(array, style) {
    var tr = new Element("tr", {'style': style});
    array.each(function(elem) {
        tr.insert(new Element("td").update(elem));
    });

    return tr;
}

function toggleIncome(id) {
    var table = $(id);

    table.childElements().each(function (elem, index) {
        if (index != 0) {
            elem.style.display = (elem.style.display == 'none' ? '' : 'none');
        }
    });
}

function toggleBuildings(id) {
    var table = $(id);

    table.childElements().each(function (elem, index) {
        if (index > 1) {
            elem.style.display = (elem.style.display == 'none' ? '' : 'none');
        }
    });
}

function toggleVP(id) {
    $(id).style.display = ($(id).style.display == 'none' ? '' : 'none');
}

function commentAnchor(string) {
    return string.replace(/[^A-Za-z0-9]/g, "").toLowerCase();
}

function drawFactions() {
    $("factions").innerHTML = "";

    var order = state.order;
    if (currentFaction && order.indexOf(currentFaction) >= 0) {
        while (order[0] != currentFaction) {
            order.push(order.shift());
        }
    }

    order.each(function(name) {
        name = name;
        var faction = state.factions[name];
        var color = faction.color;
        var title = factionDisplayName(faction);

        var style ='float: left; margin-right: 20px; ';
        if (faction.passed) {
            style += 'opacity: 0.5';
            title += ", passed";
        }

        if (faction.start_player) {
            title += ", start player";
        }

        var container = new Element('div', { 'class': 'faction-board' });
        var board = makeBoard(color, title, '', style);
        container.insert(board);
        var info = new Element('div', {'class': 'faction-info' });
        board.insert(info);

        if (faction.vp_source) {
            var vp_id = faction.name + "/vp";
            var vp_breakdown = new Element('table', {'id': vp_id,
                                                     'style': 'display: none',
                                                     'class': 'vp-breakdown'});
            board.insert(vp_breakdown);
            vp_breakdown.insert("<tr><td colspan=2><b>VP breakdown</b></td></tr>")
            $H(faction.vp_source).sortBy(function(a) { return -a.value}).each(function(record) {
                vp_breakdown.insert("<tr><td>#{key}<td>#{value}</tr>".interpolate(record));
            });
        }

        faction.vp_id = vp_id;
        info.insert(new Element('div').update(
            "#{C} c, #{W} w, #{P}<span style='color:#888'>/#{MAX_P}</span> p, <a href='javascript:toggleVP(\"#{name}/vp\")'>#{VP} vp</a>, #{P1}/#{P2}/#{P3} pw".interpolate(faction)));
        if (faction.BON4 > 0) {
            faction.ship_bonus = " (+1)";
        }

        var levels = [];

        if (faction.dig.max_level > 0) {
            var dig = "dig level #{dig.level}<span style='color:#888'>/#{dig.max_level}</span>".interpolate(faction);
            levels.push(dig);
        }

        if (faction.teleport) {
            levels.push("range " + faction[faction.teleport.type + "_range"] + "/" + faction[faction.teleport.type + "_max_range"]);
        }

        if (faction.ship.max_level > 0) {
            var ship = "ship level #{ship.level}<span style='color:#888'>/#{ship.max_level}</span>".interpolate(faction);
            if (faction.BON4 > 0) {
                ship += " (+1)";
            }
            levels.push(ship);
        }

        info.insert(new Element('div').update(levels.join(", ")));

        info.insert("<div></div>");

        var buildings_id = "buildings-" + name;
        var buildings = new Element('table', {'class': 'building-table', 'id': buildings_id});
        info.insert(buildings);

        var b = ['D', 'TP', 'TE', 'SH', 'SA'];
        var count = [];
        var cost = [];
        var income = [];

        b.each(function(key) {
            record = faction.buildings[key];
            record.key = key;
            var text = "#{level}/#{max_level}".interpolate(record);
            if (record.level == record.max_level && record.max_level > 3) {
                text = "<span style='color: red'>" + text + "</span>";
            }
            count.push(text);
            cost.push("#{advance_cost.C}c,&#160;#{advance_cost.W}w".interpolate(record));
            if (record.level == record.max_level) {
                income.push("");
            } else {
                var income_delta = [];
                ["C", "W", "P", "PW"].each(function(type) {
                    var type_income = record.income[type];
                    if (!type_income) { return; }
                    var delta = type_income[record.level + 1] - type_income[record.level];
                    if (delta > 0) {
                        income_delta.push(delta + type.toLowerCase());
                    }
                });
                if (income_delta.size() > 0) {
                    income.push("+" + income_delta.join(",&#160;"));
                } else {
                    income.push("");
                }
            }
        });

        buildings.insert(rowFromArray(b, '').insert("<td><a href='javascript:toggleBuildings(\"" + buildings_id + "\")'>+</a>"));
        buildings.insert(rowFromArray(count, ''));
        buildings.insert(rowFromArray(cost, 'display: none'));
        buildings.insert(rowFromArray(income, 'display: none'));

        var income_id = "income-" + name;
        var income = new Element('table', {'class': 'income-table', 'id': income_id});
        info.insert(income);

        if (faction.income) {
	    var row = new Element('tr');
            if (faction.income.P > faction.MAX_P - faction.P) {
                faction.income.P_style = "style='color: #f00'";
            }
            if (faction.income.PW > faction.P1 * 2 + faction.P2) {
                faction.income.PW_style = "style='color: #f00'";
            }

	    row.update("<td>Income:<td>total<td>#{C}c<td>#{W}w<td #{P_style}>#{P}p<td #{PW_style}>#{PW}pw".interpolate(faction.income));
	    row.insert(new Element('td').update("<a href='javascript:toggleIncome(\"" + income_id + "\")'>+</a>"));
            income.insert(row);
        }

        if (faction.income_breakdown) {
            income.insert(Element('tr', {'style': 'display: none'}).update("<td colspan=6><hr>"));
            $H(faction.income_breakdown).each(function(elem, ind) {
                if (!elem.value) {
                    return;
                }

                elem.value.key = elem.key;
                var row = new Element('tr', {'style': 'display: none'});
                income.insert(row.update("<td><td>#{key}<td>#{C}<td>#{W}<td>#{P}<td>#{PW}".interpolate(elem.value)));
            });
        }

        if (faction.vp_projection) {
            var vp_proj_id = "vp-projection-" + name;
            var vp_proj = new Element('table', {'class': 'income-table', 'id': vp_proj_id});
            info.insert(vp_proj);
            {
	        var row = new Element('tr');
	        row.update("<td>VP projection:<td>total<td>#{total}".interpolate(faction.vp_projection));
	        row.insert(new Element('td').update("<a href='javascript:toggleIncome(\"" + vp_proj_id + "\")'>+</a>"));
                vp_proj.insert(row);
            }

            vp_proj.insert(Element('tr', {'style': 'display: none'}).update("<td colspan=3><hr>"));
            $H(faction.vp_projection).each(function(elem, ind) {
                if (!elem.value || elem.key == "total") {
                    return;
                }

                var row = new Element('tr', {'style': 'display: none'});
                vp_proj.insert(row.update("<td><td>#{key}<td style='white-space: nowrap'>#{value}</nobr>".interpolate(elem)));
            });            
        }

        renderColorCycle(container, faction.color);
        renderTreasury(container, faction, name);
        
        $("factions").insert(container);
    });
    
    var pool = makeBoard("orange", "Pool", 'pool');
    renderTreasury(pool, state.pool, 'pool');
    $("factions").insert(pool);
}

function drawLedger() {
    var ledger = $("ledger");
    ledger.innerHTML = "";
    if ($("recent_moves")) {
        $("recent_moves").update("");
    }

    state.ledger.each(function(record, index) {
        if (record.comment) {
            ledger.insert("<tr id='" + commentAnchor(record.comment) + "'>" +
                          "<td><td colspan=13><b>" + 
                          record.comment.escapeHTML() +
                          "</b>" +
                          "<td><a href='" + showHistory(index + 1) +
                          "'>show history</a></tr>");

            var move_entry = new Element("tr");
            move_entry.insert(new Element("td", {"colspan": 2, "style": "font-weight: bold"}).update(
                record.comment.escapeHTML()));
        } else {
            record.bg = colors[state.factions[record.faction].color];
            record.fg = (record.bg == '#000000' ? '#ccc' : '#000');
            record.commands = record.commands.escapeHTML();

            if ($("recent_moves")) {
                if (record.faction == currentFaction &&
                    !/^(leech|decline)/i.match(record.commands)) {
                    $("recent_moves").update("");
                }

                var move_entry = new Element("tr");
                move_entry.insert(new Element("td").insert(
                    coloredFactionSpan(record.faction)));
                move_entry.insert(new Element("td").insert(
                    record.commands));
                $("recent_moves").insert(move_entry);
            }

            var row = "<tr><td style='background-color:#{bg}; color: #{fg}'>#{faction}".interpolate(record);
            ["VP", "C", "W", "P", "PW", "CULT"].each(function(key) {
                var elem = record[key];
                if (key != "CULT") { elem.type = key };
                if (!elem.delta) {
                    elem.delta = '';
                } else if (elem.delta > 0) {
                    elem.delta = "+" + elem.delta;
                }
                row += "<td class='ledger-delta'>#{delta}<td class='ledger-value'>#{value}&#160;#{type}</span>".
                    interpolate(elem);
            });

            var leech = "";
            $H(record.leech).each(function (elem, index) {
                if (elem.key == "black") {
                    elem.color = "#aaa";
                } else {
                    elem.color = "#000";
                }
                elem.key = colors[elem.key];
                leech += "<span style='color: #{color}; background-color: #{key}'>#{value}</span>&#160;".interpolate(elem);
            });
            row += "<td class='ledger-delta'>" + leech;

            row += "<td class='ledger-delta'>#{commands}</tr>".interpolate(record);
            ledger.insert(row);
            if (record.warning) {
                ledger.insert("<tr><td colspan=14><td><span class='warning'>" + 
                              record.warning.escapeHTML() +
                              "</span></tr>")
            }
        }
    });
}

function showHistory(row) {
    var loc = document.location.href;
    loc = loc.replace(/\/max-row=.*/, '');
    return "/game/" + params.game + "/max-row=" + row;
}

function drawScoringTiles() {
    var container = $("scoring");
    container.innerHTML = "";

    state.score_tiles.each(function(record, index) {
        var style = '';
        if (record.active) {
            style = 'background-color: #d0ffd0';
        } else if (record.old) {
            style = 'opacity: 0.5';
        }
        var tile = new Element('div', {'class': 'scoring', 'style': style});
        tile.insert(new Element('div', {'style': 'float: right; border-style: solid; border-width: 1px; '}).update("r" + (index + 1)));
        tile.insert(new Element('div').update(
            "<div class='scoring-head'>vp:</div><div>#{vp_display}</div>".interpolate(record)));
	if (record.income_display) {
            record.style = cultStyle(record.cult);
            tile.insert(new Element('div').update(
                "<div class='scoring-head'>income:</div><div><span #{style}>#{income_display}</span></div>".interpolate(record)));
	}
        container.insert(tile);
    });
}

function coloredFactionSpan(faction_name) {
    record = {};
    if (state.factions[faction_name]) {
        record.bg = colors[state.factions[faction_name].color];
        record.fg = (record.bg == '#000000' ? '#ccc' : '#000');
        record.display = factionDisplayName(state.factions[faction_name]);
    } else {
        var players = {};
        state.players.each(function (value, index) {
            players["player" + (index + 1)] = value.name.escapeHTML();
        });
        if (players[faction_name]) {
            return faction_name + " (" + players[faction_name] + ")"
        } else {
            return faction_name;
        }
    }

    return "<span style='background-color:#{bg}; color: #{fg}'>#{display}</span>".interpolate(record);
}

function factionDisplayName(faction, fg) {
    if (faction.registered) {
        faction.player_escaped = faction.player.escapeHTML();
        return "#{display} (<a style='color: inherit' href='/player/#{username}'>#{player_escaped}</a>)".interpolate(faction);
    } else {
        return "#{display} (#{player})".interpolate(faction);
    }
}

var allowSaving = false;

function drawActionRequired() {
    var parent = $("action_required");

    if (!parent) {
        return;
    }

    parent.innerHTML = "";

    var needMoveEntry = false;

    allowSaving = true;

    state.action_required.each(function(record, index) {
        if (record.type == 'full') {
            record.pretty = 'should take an action';
        } else if (record.type == 'leech') {
            record.from_faction_span = coloredFactionSpan(record.from_faction);
            record.pretty = 'may gain #{amount} power from #{from_faction_span}'.interpolate(record);
            if (record.actual != record.amount) {
                record.pretty += " (actually #{actual} power)".interpolate(record);
            }
        } else if (record.type == 'transform') {
            if (record.amount == 1) {
                record.pretty = 'may use a spade (click on map to transform)'.interpolate(record);
            } else if (record.amount == null) {
                record.pretty = 'may transform a space for free (click on map)'.interpolate(record);
            } else {
                record.pretty = 'may use #{amount} spades (click on map to transform)'.interpolate(record);
            }
            $("map").onclick = hexClickHandler(function(hex) {
                $("map").onclick = null;
                appendAndPreview("transform " + hex);
            });
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
        } else if (record.type == 'bridge') {
            record.pretty = 'may place a bridge'.interpolate(record);
        } else if (record.type == 'favor') {
            if (record.amount == 1) {
                record.pretty = 'may take a favor tile'.interpolate(record);
            } else {
                record.pretty = 'may take #{amount} favor tiles'.interpolate(record);
            }
        } else if (record.type == 'dwelling') {
            record.pretty = 'should place a dwelling';
        } else if (record.type == 'upgrade') {
            record.pretty = 'should place a free #{to_building} upgrade'.interpolate(record);
        } else if (record.type == 'bonus') {
            record.pretty = 'should pick a bonus tile';
        } else if (record.type == 'gameover') {
            record.pretty = "<span>The game is over\n</span>";
            var table = "";
            $H(state.factions).sortBy(function(a) { return -a.value.VP }).each(function(elem) {
                elem.faction_span = coloredFactionSpan(elem.key);
                table += "<tr><td>#{faction_span}<td> #{value.VP}</tr>\n".interpolate(elem);
            });
            record.pretty += "<table>" + table + "</table>";
        } else if (record.type == 'faction') {
            record.pretty = '#{player} should pick a faction'.interpolate(record);
        } else if (record.type == 'planning') {
            record.pretty = 'are planning';
        } else {
            record.pretty = '?';
        }

	if (record.faction) {
            record.faction_span = coloredFactionSpan(record.faction);
	} else {
	    record.faction_span = "";
	}

        var row = new Element("div", {'style': 'margin: 3px'}).update("#{faction_span} #{pretty}</div>".interpolate(record));
        parent.insert(row);

        if (currentFaction &&
            (record.faction == currentFaction ||
             record.player_index == currentFaction)) {
            addFactionInput(parent, record, index);
            needMoveEntry = true;
            allowSaving = false;
        }
    });

    if (state.history_view) {
        return;
    }

    if (currentFaction && $("data_entry").innerHTML == "") {
        $("data_entry").insert("<div id='data_entry_tabs'></div>");
        $("data_entry_tabs").insert("<button onclick='dataEntrySelect(\"move\"); updateMovePicker();' id='data_entry_tab_move' class='tab' accesskey='m'>Moves</button>");
        $("data_entry_tabs").insert("<button onclick='initPlanIfNeeded(); dataEntrySelect(\"planning\")' id='data_entry_tab_planning' class='tab' accesskey='p'>Planning</button>");
        $("data_entry_tabs").insert("<button onclick='dataEntrySelect(\"recent\")' id='data_entry_tab_recent' class='tab' accesskey='r'>Recent Moves</button>");
        if (state.options["email-notify"]) {
            var style = "";
            if (newChatMessages()) {
                style = "color: red"
            }
            var chat_button = new Element("button", {"onclick": "initChatIfNeeded(); dataEntrySelect('chat')", "id": 'data_entry_tab_chat', "class":'tab', "style": style, "accesskey":  'c'});
            var label = "Chat";
            if (state.chat_unread_message_count > 0) {
                label += " [#{chat_unread_message_count} unread]".interpolate(state);
            } else if (state.chat_message_count > 0) {
                label += " [#{chat_message_count}]".interpolate(state);
            }
            chat_button.updateText(label);
            $("data_entry_tabs").insert(chat_button);
        }
        $("data_entry").insert("<div id='move_entry' class='tab_content'></div>");
        $("data_entry").insert("<div id='planning_entry' class='tab_content'></div>");
        $("data_entry").insert("<div id='recent_entry' class='tab_content'></div>");
        $("data_entry").insert("<div id='chat_entry' class='tab_content'></div>");
        dataEntrySelect("move");
    }

    if ($("planning_entry") && $("planning_entry").innerHTML == "") {
        var input = new Element("textarea", {"id": "planning_entry_input",
                                             "style": "font-family: monospace; width: 60ex; height: 12em;" } );
        $("planning_entry").insert(input);
        $("planning_entry").insert("<div style='padding-left: 2em'><button id='planning_entry_action' onclick='javascript:previewPlan()'>Show Result</button><button id='planning_entry_action' onclick='javascript:savePlan()'>Save Plan</button><br><div id='planning_entry_explanation'>Use this entry box to leave notes for yourself, or to plan your coming moves using the same input format as for normal play. View the effects of the plan with 'show result' or save the plan / notes for later with 'save plan'.</div></div>");
    }

    if ($("recent_entry") && $("recent_entry").innerHTML == "") {
        var recent = new Element("table", { "id": "recent_moves" });
        $("recent_entry").insert(recent);
    }

    if (state.options["email-notify"] &&
        $("chat_entry") && $("chat_entry").innerHTML == "") {
        $("chat_entry").insert(new Element("table", {"id": "chat_messages" }));
        var input = new Element("textarea", {"id": "chat_entry_input",
                                             "style": "font-family: monospace; width: 60ex; height: 5em;" } );
        $("chat_entry").insert(input);
        $("chat_entry").insert(new Element("br"));
        $("chat_entry").insert(new Element("button", {"id": "chat_entry_submit", "onclick": "javascript:sendChat()"}).update("Send"));
    }

    if (needMoveEntry && $("move_entry").innerHTML == "") {
        var table = new Element("table");
        $("move_entry").insert(table);
        var row = new Element("tr");
        table.insert(row);
        
        var entry_cell = new Element("td", {"valign": "top",
                                            "style": "width: 40ex"});
        row.insert(entry_cell);
        var input = new Element("textarea", {"id": "move_entry_input",
                                             "onInput": "javascript:moveEntryInputChanged()",
                                             "style": "font-family: monospace; height: 6em; width: 100%" } );
        $(entry_cell).insert(input);
        $(entry_cell).insert("<div style='padding-left: 2em'><button id='move_entry_action' onclick='javascript:preview()'>Preview</button><br><div id='move_entry_explanation'></div>");

        var picker_cell = new Element("td", {"valign": "top",
                                             "style": "padding-left: 3em"});
        row.insert(picker_cell);
        $(picker_cell).insert(new Element("div", { 'id': 'move_picker' }));
    }

    updateMovePicker();
}

function dataEntrySelect(select) {
    $$("#data_entry_tabs button.tab").each(function(tab) {
        if (tab.id == "data_entry_tab_" + select) {
            tab.style.fontWeight = "bold";
        } else {
            tab.style.fontWeight = "normal";
        }
    });

    $$("#data_entry div.tab_content").each(function(tab) {
        if (tab.id == select + "_entry") {
            tab.style.display = "block";
        } else {
            tab.style.display = "none";
        }
    });

    moveEntryInputChanged();
}

function addTakeTileButtons(parent, index, prefix, id) {
    var div = new Element("div", { "id": "leech-" + index + "-" + id,
                                   "style": "padding-left: 2em" });
    $H(state.pool).sortBy(naturalSortKey).each(function(tile) {
        if (tile.value < 1 || !tile.key.startsWith(prefix)) {
            return;
        }

        if (prefix == "FAV" && state.factions[currentFaction][tile.key] > 0) {
            return;
        }

        var container = new Element("div", {"style": "display: inline-block"});

        var button = new Element("button").update(tile.key);
        button.onclick = function() {
            gainResource(index, '', tile.key, id);
        };
        container.insert(button);
        container.insert(new Element("br"));

        renderTreasuryTile(container, currentFaction,
                           tile.key, state.pool[tile.key]);
        
        div.insert(container);
    });
    parent.insert(div);
}

function addFactionInput(parent, record, index) {
    if (record.type == "leech") {
        parent.insert("<div id='leech-" + index + "' style='padding-left: 2em'><button onclick='javascript:acceptLeech(" + index + ")'>Accept</button> <button onclick='javascript:declineLeech(" + index + ")'>Decline</button></div>")
    }
    if (record.type == "cult") {
        var amount = record.amount;
        var div = new Element("div", { "id": "leech-" + index + "-0",
                                       "style": "padding-left: 2em" });
        cults.each(function(cult) {
            var button = new Element("button").update(cult.capitalize());
            button.onclick = function() {
                gainResource(index, amount == 1 ? '' : amount, cult, 0);
            };
            div.insert(button);                                               
        });
        parent.insert(div);
    }
    if (record.type == "town") {
        addTakeTileButtons(parent, index, "TW");
    }
    if (record.type == "favor") {
        for (var i = 0; i < record.amount; ++i) {
            addTakeTileButtons(parent, index, "FAV", i);
        }
    }
    if (record.type == "bonus") {
        addTakeTileButtons(parent, index, "BON", i);
    }
    if (record.type == "faction") {
        var div = new Element("div", { "id": "leech-" + index + "-0",
                                       "style": "padding-left: 2em" });
        var boards = { "green": ["witches", "auren"],
                       "blue": ["mermaids", "swarmlings" ],
                       "black": ["darklings", "alchemists"],
                       "brown": ["halflings", "cultists"], 
                       "yellow": ["nomads", "fakirs"],
                       "red": ["giants", "chaosmagicians"],
                       "gray": ["dwarves", "engineers"] 
                     };

        $H(state.factions).each(function(faction) {
            delete boards[faction.value.color];
        });

        $H(boards).each(function(board) {
            board.value.sort().each(function(faction) {
                var button = new Element("button").update(faction);
                button.onclick = function() {
                    appendCommand("setup " + faction + "\n");
                };
                div.insert(button);
            });
            div.insert("<br>");
        });
        parent.insert(div);
    }
    if (record.type == "dwelling") {
        var div = new Element("div", { "id": "leech-" + index,
                                       "style": "padding-left: 2em" });
        $H(state.map).sortBy(naturalSortKey).each(function(elem) {
            var hex = elem.value;

            if (hex.row == null) {
                return;
            }

            if (hex.color != state.factions[currentFaction].color) {
                return;
            }

            if (hex.building) {
                return;
            }

            var button = new Element("button").update(elem.key);
            button.onclick = function() {
                $("leech-" + index).style.display = "none";
                appendCommand("Build #{key}\n".interpolate(elem));
            };
            div.insert(button);                                               
        });
        parent.insert(div);
    }
    if (record.type == "upgrade") {
        var div = new Element("div", { "id": "leech-" + index,
                                       "style": "padding-left: 2em" });
        $H(state.map).sortBy(naturalSortKey).each(function(elem) {
            var hex = elem.value;
            
            if (hex.row == null) {
                return;
            }

            if (hex.color != state.factions[currentFaction].color) {
                return;
            }

            if (hex.building != record.from_building) {
                return;
            }

            var button = new Element("button").update(elem.key);
            button.onclick = function() {
                $("leech-" + index).style.display = "none";
                appendCommand("Upgrade " + elem.key + " to #{to_building}\n".interpolate(record));
            };
            div.insert(button);                                               
        });
        parent.insert(div);
    }
    if (record.type == "bridge") {
        var div = new Element("div", { "id": "leech-" + index,
                                       "style": "padding-left: 2em" });
        var already_added = {};

        $H(state.map).sortBy(naturalSortKey).each(function(elem) {
            var hex = elem.value;

            if (hex.row == null) {
                return;
            }

            if (hex.color != state.factions[currentFaction].color) {
                return;
            }

            if (!hex.building) {
                return;
            }

            $H(hex.bridgable).each(function(to) {
                var br = [elem.key, to.key].sort().join(":");
                if (already_added[br]) {
                    return;
                }
                already_added[br] = true;
                var button = new Element("button").update(br);
                button.onclick = function() {
                    $("leech-" + index).style.display = "none";
                    appendCommand("bridge " + br);
                };
                div.insert(button);
            });
        });
        parent.insert(div);
    }
}

function appendCommand(cmd) {
    appendAndPreview(cmd);
}

function acceptLeech(index) {
    var record = state.action_required[index];
    $("leech-" + index).style.display = "none";
    appendCommand("Leech #{amount} from #{from_faction}\n".interpolate(record));
}

function declineLeech(index) {
    var record = state.action_required[index];
    $("leech-" + index).style.display = "none";
    appendCommand("Decline #{amount} from #{from_faction}\n".interpolate(record));
}

function gainResource(index, amount, resource, id) {
    var record = state.action_required[index];
    record.amount_pretty = amount;
    record.resource = resource;
    $("leech-" + index + "-" + id).style.display = "none";
    if (resource.startsWith("BON")) {
        appendCommand("Pass #{resource}\n".interpolate(record));
    } else {
        appendCommand("+#{amount_pretty}#{resource}".interpolate(record));
    }
}

function moveEntryInputChanged() {
    if (!$("move_entry_input")) {
        return;
    }

    $("move_entry_input").oninput = null;
    $("move_entry_action").innerHTML = "Preview";
    $("move_entry_action").onclick = preview;
    $("move_entry_action").enable();
    $("move_entry_explanation").innerHTML = "";
} 

function dataEntrySetStatus(disabled) {
    $("data_entry").descendants().each(function (elem) {
        elem.disabled = disabled;
    });
}

function moveEntryAfterPreview() {
    if ($("move_entry_action")) {
        $("move_entry_explanation").innerHTML = "";
        $("move_entry_action").innerHTML = "Preview";
        $("move_entry_action").onclick = preview;

        if ($("move_entry_input").value != "") {
            if ($("error").innerHTML != "") {
                $("move_entry_explanation").innerHTML = "Can't save yet - input had errors";
            } else if (!allowSaving) {
                $("move_entry_explanation").innerHTML = "Can't save yet - it's still your turn to move. (Also see the 'wait' command).";
            } else {
                $("move_entry_action").innerHTML = "Save";
                $("move_entry_action").onclick = save;
            }
        }
    }
    if ($("move_entry_input")) {
        $("move_entry_input").oninput = moveEntryInputChanged;
    }
    dataEntrySetStatus(false);
    updateMovePicker();
    // Disable preview until something changes, but don't disable a save
    if ($("move_entry_action") &&
        $("move_entry_action").innerHTML == "Preview") {
        $("move_entry_action").disable();
    }
}

function updateMovePicker() {
    var picker = $('move_picker');
    var faction = state.factions[currentFaction];
    if (!picker || !faction) {
        return;
    }

    var undo = addUndoToMovePicker(picker, faction);
    var pass = addPassToMovePicker(picker, faction);
    var action = addActionToMovePicker(picker, faction);
    var build = addBuildToMovePicker(picker, faction);
    var upgrade = addUpgradeToMovePicker(picker, faction);
    var burn = addBurnToMovePicker(picker, faction);
    var convert = addConvertToMovePicker(picker, faction);
    var dig = addDigToMovePicker(picker, faction);
    var send = addSendToMovePicker(picker, faction);
    var advance = addAdvanceToMovePicker(picker, faction);
    var connect = addConnectToMovePicker(picker, faction);
}

function makeSelectWithOptions(options) {
    var select = new Element("select");
    options.each(function (elem) {
        select.insert(new Element("option").update(elem));
    });
    return select;
}

function ensureMoveEntryNewRow() {
    var input = $("move_entry_input").value;
    if (input.length > 0 &&
        input[input.length - 1] != "\n") {
        $("move_entry_input").value += "\n";
    }
}

function appendAndPreview(command) {
    ensureMoveEntryNewRow();
    $("move_entry_input").value += command;
    preview();
}

function insertOrClearPickerRow(picker, id) {
    var row = $(id);
    if (!row) {
        row = new Element("div", {"id": id});
        picker.insert(row);
    } else {
        row.update("");
    }

    return row;
}

function addUndoToMovePicker(picker, faction) {
    var validate = function() {
        if ($("move_entry_input").value == "") {
            undo.disable();
            done.disable();
            return;
        }
        undo.enable();

        // "Done" only makes sense when this is the only faction that has
        // not yet passed.
        var active_count = 0;
        var passed_count = 0;
        $H(state.factions).each(function (elem) {
            if (elem.value.passed) {
                passed_count++;
            } else {
                active_count++;
            }
        });
        if (active_count == 1 &&
            !faction.passed &&
            faction.allowed_actions) {
            done.enable();
        } else {
            done.disable();
        }
    };
    var execute_undo = function() {
        var value = $("move_entry_input").value;
        var rows = value.split(/\n/);
        // Remove all trailing empty lines
        while (rows.length && rows[rows.length - 1] == "") {
            rows.pop();
        }
        // The remove the last real line
        rows.pop();
        $("move_entry_input").value = rows.join("\n");
        preview();
    };
    var execute_done = function() {
        appendAndPreview("done");
    }
        
    var row = insertOrClearPickerRow(picker, "move_picker_undo");
    var undo = new Element("button").update("Undo");
    undo.onclick = execute_undo;
    undo.disable();

    var done = new Element("button").update("Done");
    done.onclick = execute_done;
    done.disable();

    row.insert(undo);
    row.insert(" /  ");
    row.insert(done);
    
    validate();
    row.show();

    return row;
}

function addPassToMovePicker(picker, faction) {
    var validate = function() {
        if (state.round < 6 &&
            bonus_tiles.value == "-") {
            button.disable();
        } else {
            button.enable();
        }
    };
    var execute = function() {
        var command = "pass";
        if (state.round != 6) {
            command += " " + bonus_tiles.value;
        }
        appendAndPreview(command);
    };

    var row = insertOrClearPickerRow(picker, "move_picker_pass");
    var button = new Element("button").update("Pass");
    button.onclick = execute;
    button.disable();
    row.insert(button);

    var bonus_tiles = makeSelectWithOptions(["-"]);
    bonus_tiles.onchange = validate;
    if (state.round < 6) {
        row.insert(" and take tile ");
        $H(state.pool).sortBy(naturalSortKey).each(function (tile) {
            if (tile.key.startsWith("BON") && tile.value > 0) {
                bonus_tiles.insert(new Element("option").update(tile.key));
            }
        });
        row.insert(bonus_tiles);
    }
    
    if (faction.allowed_actions) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function addActionToMovePicker(picker, faction) {
    var validate = function() {
        if (action.value == "-") {
            button.disable();
        } else {
            button.enable();
        }
    };
    var execute = function() {
        var command = "action " + action.value;
        var pw_cost = state.actions[action.value].cost.PW;
        if (burn.checked && pw_cost > faction.P3) {
            command = "burn " + (pw_cost - faction.P3) + ". " + command;
        }
        appendAndPreview(command);
    };

    var row = insertOrClearPickerRow(picker, "move_picker_action");
    var button = new Element("button").update("Action");
    button.onclick = execute;
    button.disable();
    row.insert(button);

    var action = makeSelectWithOptions([]);
    var generate = function () {
        action.update("");
        action.insert(new Element("option").update("-"));
        action.onchange = validate;
        var pw = faction.P3;
        if (burn.checked) { pw += faction.P2 / 2 };
        $H(state.pool).sortBy(naturalSortKey).each(function (elem) {
            var key = elem.key;
            if (key.startsWith("ACT") &&
                !(state.map[key] && state.map[key].blocked) &&
                (pw >= state.actions[key].cost.PW)) {
                action.insert(new Element("option").update(key));
            }
        });
        $H(faction).sortBy(naturalSortKey).each(function (elem) {
            var key = elem.key;
            var fkey = elem.key + "/" + faction.name;
            if (elem.value > 0 &&
                state.actions[key] &&
                !(state.map[fkey] && state.map[fkey].blocked)) {
                action.insert(new Element("option").update(key));
            }
        });
    }
    var burn = new Element("input", {"id": "move_picker_action_burn",
                                     "checked": true,
                                     "type": "checkbox"});
    burn.onchange = generate;

    generate();

    row.insert(action);
    row.insert(new Element("label", {'for':'move_picker_action_burn'}).
               update(", burn power if needed"));
    row.insert(burn);
    
    if (faction.allowed_actions) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function addBuildToMovePicker(picker, faction) {
    var validate = function() {
        if (location.value == "-") {
            button.disable();
        } else {
            button.enable();
        }
    };
    var execute = function() {
        var command = "build " + location.value;
        var rows = $("move_entry_input").value.split(/\n/);
        while (rows.last() == "") {
            rows.pop();
        }

        if (rows.last() == "transform " + location.value) {
            rows.pop();
            rows.push(command);
            $("move_entry_input").value = rows.join("\n");
        } else {
            appendAndPreview(command);
        }
    };

    var row = insertOrClearPickerRow(picker, "move_picker_build");
    var button = new Element("button").update("Build");
    button.onclick = execute;

    var location = makeSelectWithOptions([]);
    location.onchange = validate;
    var location_count = 0;

    if (faction.allowed_sub_actions.build) {
        $H(faction.allowed_build_locations).each(function (elem) {
            var loc = elem.key;
            location.insert(new Element("option").update(loc));
            location_count++;
        });
        if (!location_count) {
            location.insert(new Element("option").update("-"));
        }         
    } else if (faction.allowed_actions) {
        location.insert(new Element("option").update("-"));
        faction.reachable_build_locations.each(function (loc) {
            location.insert(new Element("option").update(loc));
            location_count++;
        });
    }

    row.insert(button);
    row.insert(" in ");
    row.insert(location);

    validate();
    
    if (faction.buildings.D.level < faction.buildings.D.max_level &&
        (faction.allowed_actions ||
         faction.allowed_sub_actions.build) &&
        location_count > 0) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function addUpgradeToMovePicker(picker, faction) {
    var validate = function() {
        if (location.value == "-") {
            button.disable();
        } else {
            button.enable();
        }
    };
    var execute = function() {
        var command = "upgrade " + location.value;
        appendAndPreview(command);
    };

    var row = insertOrClearPickerRow(picker, "move_picker_upgrade");
    var button = new Element("button").update("Upgrade");
    button.onclick = execute;
    button.disable();
    row.insert(button);

    var location = makeSelectWithOptions(["-"]);
    var location_count = 0;
    location.onchange = validate;

    var upgrade = $H({ 'TP': 'D',
                       'TE': 'TP',
                       'SA': 'TE',
                       'SH': 'TP' });
    $H(state.map).sortBy(naturalSortKey).each(function (elem) {
        var hex = elem.value;
        var id = elem.key;
        if (hex.row == null || 
            hex.color != faction.color) {
            return
        }
        upgrade.each(function (type_elem) {
            var wanted_new = type_elem.key;
            var wanted_old = type_elem.value;
            if (hex.building != wanted_old) {
                return;
            }
            if (faction.buildings[wanted_new].level >=
                faction.buildings[wanted_new].max_level) {
                return;
            }
            var costs = faction.buildings[wanted_new].advance_cost;
            var can_afford = true;
            $H(costs).each(function (cost_elem) {
                if (faction[cost_elem.key] < cost_elem.value) {
                    can_afford = false;
                }
            });
            if (can_afford) {
                location.insert(new Element("option").update(
                    id + " to " + wanted_new));
                location_count++;
            }
        });
    });
    row.insert(location);
    
    if (faction.allowed_actions && location_count > 0) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function addBurnToMovePicker(picker, faction) {
    var validate = function() {
        if (amount.value == '-') {
            button.disable()
            return;
        }
        button.enable()
    };
    var execute = function() {
        var command = "burn " + amount.value;
        appendAndPreview(command);
    };

    var row = insertOrClearPickerRow(picker, "move_picker_burn");

    var button = new Element("button").update("Burn");
    button.onclick = execute;
    button.disable();

    var amounts = ['-'];
    for (var i = 0; i <= faction.P2 / 2; ++i) {
        amounts.push(i);
    }
    var amount = makeSelectWithOptions(amounts);
    amount.onchange = validate;

    row.insert(button);
    row.insert(amount);
    row.insert(" power");

    if (faction.P2 > 1 &&
        (faction.allowed_actions > 0||
         faction.allowed_sub_actions.burn > 0)) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function addConvertToMovePicker(picker, faction) {
    var validate = function() {
        if (amount.value == '-') {
            button.disable()
            return;
        }
        button.enable()
    };
    var execute = function() {
        var types = type.value.split(/,/);
        var from_type = types[0];
        var to_type = types[1];
        var rate = faction.exchange_rates[from_type][to_type];
        var from = rate * amount.value + from_type;
        var to = amount.value + to_type;
        var command = "convert " + from + " to " + to;
        appendAndPreview(command);
    };
    faction.PW = faction.P3;
    if (faction.CONVERT_W_TO_P) {
        faction.exchange_rates["W"]["P"] = 1;
    }

    var generate = function () {
        amount.update("");
        if (type.value == '-') {
            amount.insert(new Element("option").update("-"));
        } else {
            var types = type.value.split(/,/);
            var from_type = types[0];
            var to_type = types[1];
            var rate = faction.exchange_rates[from_type][to_type];
            for (var i = 1; rate * i <= faction[from_type]; i++) {
                amount.insert(new Element("option").update(i));
            }
        }
    };

    var row = insertOrClearPickerRow(picker, "move_picker_convert");

    var button = new Element("button").update("Convert");
    button.onclick = execute;
    button.disable();

    var type = makeSelectWithOptions(["-"]);
    type.onchange = function() {
        generate();
        validate();
    };

    var rates = $H(faction.exchange_rates);
    rates.each(function (elem) {
        var from = elem.key;
        var to = $H(elem.value);
        to.each(function (to_elem) {
            var to_type = to_elem.key;
            var rate = to_elem.value;

            if (faction[from] >= rate) {
                var label = from + " to " + to_type;
                if (rate > 1) {
                    label = rate + label;
                }
                type.insert(new Element("option",
                                        { "value": from + "," + to_type }).
                            update(label));
            }
        });
    });

    var amount = makeSelectWithOptions(["-"]);

    row.insert(button);
    row.insert(type);
    row.insert(amount);
    row.insert(" times");
 
    if (faction.allowed_actions > 0 ||
        faction.allowed_sub_actions.burn > 0) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function addDigToMovePicker(picker, faction) {
    var validate = function() {
        if (amount.value == '-') {
            button.disable()
            return;
        }
        button.enable()
    };
    var execute = function() {
        var command = "dig " + amount.value;
        appendAndPreview(command);
    };

    var row = insertOrClearPickerRow(picker, "move_picker_dig");

    var button = new Element("button").update("Dig");
    button.onclick = execute;
    button.disable();

    var amount = makeSelectWithOptions(["-"]);
    var amount_count = 0;
    amount.onchange = validate;

    var cost = $H(faction.dig.cost[faction.dig.level]);
    for (var i = 1; i <= 7; ++i) {
        var can_afford = true;
        cost.each(function (cost_elem) {
            if (i * cost_elem.value > faction[cost_elem.key]) {
                can_afford = false;
            }
        });
        if (can_afford) {
            amount_count++;
            amount.insert(new Element("option").update(i));
        }
    }

    row.insert(button);
    row.insert(amount);
    row.insert(" times");
 
    if (faction.allowed_actions || faction.allowed_sub_actions.dig) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function addSendToMovePicker(picker, faction) {
    var validate = function() {
        var cult = cults.value.toUpperCase();
        if (cult == "-") {
            button.disable()
            return;
        }
        button.enable()
    };
    var execute = function() {
        var command = "send p to " + cults.value;
        if (amount.value != 'max') {
            command += " amount " + amount.value;
        }
        appendAndPreview(command);
    };

    var row = insertOrClearPickerRow(picker, "move_picker_send");

    var button = new Element("button").update("Send");
    button.onclick = execute;
    button.disable();
    var cults = makeSelectWithOptions(["-", "Fire", "Water", "Earth", "Air"]);
    cults.onchange = validate;
    var amount = makeSelectWithOptions(["max", "3", "2", "1"]);
    amount.onchange = validate;

    row.insert(button);
    row.insert("priest to ");
    row.insert(cults);
    row.insert(" for ");
    row.insert(amount);

    if (faction.P > 0 && faction.allowed_actions) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function addAdvanceToMovePicker(picker, faction) {
    var validate = function() {
        var advance_on = track.value;
        if (advance_on == "-") {
            button.disable()
            return;
        }
        button.enable()
    };
    var execute = function() {
        var command = "advance " + track.value;
        appendAndPreview(command);
    };

    var row = insertOrClearPickerRow(picker, "move_picker_advance");

    var button = new Element("button").update("Advance");
    button.onclick = execute;
    button.disable();

    var track = makeSelectWithOptions(["-"]);
    var track_count = 0;
    track.onchange = validate;

    ["dig", "ship"].each(function (type) {
        if (faction[type].level >= faction[type].max_level) {
            return;
        }

        var can_afford = true;
        $H(faction[type].advance_cost).each(function (cost_elem) {
            if (faction[cost_elem.key] < cost_elem.value) {
                can_afford = false;
            }
        });
        if (can_afford) {
            track.insert(new Element("option").update(type));
            track_count++;
        }
    });

    row.insert(button);
    row.insert(" on ");
    row.insert(track);

    if (track_count && faction.allowed_actions) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function addConnectToMovePicker(picker, faction) {
    if (!faction.possible_towns) {
        return;
    }

    var validate = function() {
        if (location.value == "-") {
            button.disable();
        } else {
            button.enable();
        }
    };
    var execute = function() {
        appendAndPreview("connect " + location.value);
    };

    var row = insertOrClearPickerRow(picker, "move_picker_connect");
    var button = new Element("button").update("Connect");
    button.onclick = execute;

    var location = makeSelectWithOptions(["-"].concat(faction.possible_towns));
    location.onchange = validate;
    var location_count = 0;

    row.insert(button);
    row.insert(" over ");
    row.insert(location);
    row.insert(" to form town ");

    validate();
    
    if (faction.possible_towns.size() > 0) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function draw() {
    $("error").innerHTML = "";
    state.error.each(function(row) {
        $("error").insert("<div>" + row.escapeHTML() + "</div>");
    });

    if ($("main-data")) {
        $("main-data").style.display = "block";
    }

    drawMap();
    drawCults();
    drawScoringTiles();
    drawActionRequired();
    drawFactions();
    drawLedger();

    if (state.history_view > 0) {
        $("root").style.backgroundColor = "#ffeedd";
    }
}

function failed() {
    $("action_required").innerHTML = "";
    if (state.error) {
        state.error.each(function(row) {
            $("error").insert("<div>" + row.escapeHTML() + "</div>");
        });
    } else {
        $("error").insert("Couldn't load game");
    }
}

function spin() {
    $("action_required").innerHTML = '<img src="/stc/spinner.gif"></img> loading ...';
}

function init(root) {
    root.innerHTML += ' \
    <table style="border-style: none" id="main-data"> \
      <tr> \
        <td> \
          <div id="map-container"> \
            <canvas id="map" width="800" height="500"> \
              Browser not supported. \
            </canvas> \
          </div> \
        <td> \
          <div id="cult-container"> \
            <canvas id="cults" width="250" height="500"> \
              Browser not supported. \
            </canvas> \
          </div> \
        <td> \
          <div id="scoring"></div> \
    </table> \
    <div id="preview_status"></div> \
    <pre id="preview_commands"></pre> \
    <div id="error"></div> \
    <div id="action_required"></div> \
    <div id="data_entry"></div> \
    <div id="factions"></div> \
    <table id="ledger"> \
      <col></col> \
      <col span=2 ></col> \
      <col span=2 style="background-color: #e0e0f0"></col> \
      <col span=2 ></col> \
      <col span=2 style="background-color: #e0e0f0"></col> \
      <col span=2 ></col> \
      <col span=2 style="background-color: #e0e0f0"></col> \
    </table>';

}

