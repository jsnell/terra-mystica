var hex_size = 35;
var hex_width = (Math.cos(Math.PI / 6) * hex_size * 2);
var hex_height = Math.sin(Math.PI / 6) * hex_size + hex_size;

function hexCenter(row, col) {
    var y_offset = 0;
    if (!state.map["A1"]) {
        y_offset = -hex_height;
    }

    var x_offset = row % 2 ? hex_width / 2 : 0;
    var x = 5 + hex_size + col * hex_width + x_offset,
        y = 5 + hex_size + row * hex_height + y_offset;
    return [x, y];
}

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

    
    ctx.strokeStyle = contrastColor[hex.color];
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

function drawColorSymbol(ctx, color, x, y) {
    if (!useColorBlindMode()) {
        return;
    }

    ctx.save();
    ctx.translate(x, y);
    ctx.beginPath();
    ctx.lineWidth = 1.5;
    ctx.strokeStyle = contrastColor[color];
    ctx.fillStyle = contrastColor[color];

    switch (color) {
    case 'gray':
        ctx.translate(0, -3);
        ctx.rotate(Math.PI * 1.25);
        ctx.moveTo(0, 0);
        ctx.lineTo(-6, -2);
        ctx.moveTo(0, 0);
        ctx.lineTo(-2, -6);
        ctx.stroke();
        break;
    case 'red':
        ctx.arc(0, 0, 3, 0.001, Math.PI*2, false);
        ctx.fill();
        break;
    case 'yellow':
        ctx.moveTo(-3, 0);
        ctx.lineTo(3, 0);
        ctx.stroke();
        break;
    case 'brown':
        ctx.rotate(Math.PI);
        ctx.arc(0, 0, 4, 0.001, Math.PI, false);
        ctx.stroke();
        break;
    case 'black':
        ctx.rotate(Math.PI);
        ctx.arc(0, 0, 2, 0.001, Math.PI * 2, false);
        ctx.fill();
        break;
    case 'blue':
        ctx.arc(-2, 0, 2, 0.001, Math.PI, false);
        ctx.stroke();

        ctx.beginPath();
        ctx.arc(2, 0, 2, Math.PI, 0.001, false);
        ctx.stroke();
        break;
    case 'green':
        ctx.moveTo(-3, -3);
        ctx.lineTo(3, -3);
        ctx.moveTo(0, -3);
        ctx.lineTo(0, 3);
        ctx.stroke();
        break;

    case 'ice':
        ctx.moveTo(-2, 2);
        ctx.lineTo(2, 2);
        ctx.lineTo(2, -2);
        ctx.lineTo(-2, -2);
        ctx.closePath();
        ctx.stroke();
        break;

    case 'volcano':
        for (var i = 0; i < 4; ++i) {
            ctx.rotate(Math.PI / 2);
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(3, 3);
            ctx.stroke();
        }
        break;
    };
    
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
    var contrast;
    if (hex.forceColor) {
        ctx.fillStyle = hex.forceColor;
        contrast = '#000';
    } else {
        ctx.fillStyle = bgcolors[hex.color];
        contrast = contrastColor[hex.color];
    }
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
    } else if (hex.label) {
        ctx.save();
        ctx.strokeStyle = contrast;
        ctx.textAlign = 'center';
        drawText(ctx, hex.label, loc[0], loc[1], "12px Verdana");
        ctx.restore();
    }

    ctx.save();
    ctx.strokeStyle = contrast;
    ctx.textAlign = 'center';
    drawText(ctx, id, loc[0], loc[1] + 25,
             hex.town ? "bold 12px Verdana" : "12px Verdana");
    ctx.restore();

    drawColorSymbol(ctx, hex.color, loc[0] - 22, loc[1] + 12);
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

    
function drawActiveHexBorder(hex) {
    var canvas = $("map");
    if (canvas.getContext) {
        var ctx = canvas.getContext("2d");

        makeMapHexPath(ctx, hex);

        ctx.save();
        ctx.strokeStyle = "#000";
        ctx.lineWidth = 4;
        makeMapHexPath(ctx, hex);
        ctx.stroke();
        ctx.restore();

        ctx.save();
        ctx.strokeStyle = colors.activeUI;
        ctx.lineWidth = 3;
        makeMapHexPath(ctx, hex);
        ctx.stroke();
        ctx.restore();
    }
}

function drawMap() {
    var canvas = $("map");
    if (canvas.getContext) {
        canvas.width = canvas.width;
        var ctx = canvas.getContext("2d");
        ctx.scale(2, 2);

        ctx.save();
        state.bridges.each(function(bridge, index) {
            drawBridge(ctx, bridge.from, bridge.to, bridge.color);
        });

        $H(state.map).each(function(hex, index) { drawHex(ctx, hex) });
        ctx.restore();
    }
}

function hexClickHandler(fun) {
    return function (event) {
        $("menu").hide();
        var position = $("map").getBoundingClientRect();
        var x = event.clientX - position.left;
        var y = event.clientY - position.top;
        var best_dist = null;
        var best_loc = null;
        for (var r = 0; r < 10; ++r) {
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
            fun(hex_id, event);
        }
    };
}

var cults = ["FIRE", "WATER", "EARTH", "AIR"];
var cult_width = 250 / 4;

function drawCults() {
    var canvas = $("cults");
    if (canvas.getContext) {
        canvas.width = canvas.width;
        var ctx = canvas.getContext("2d");

        var x_offset = 0;

        var width = cult_width;
        var height = 500;

        ctx.save();
        ctx.scale(2, 2);        

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
            ctx.translate(8, 470);
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

function drawActiveCultBorder(cult) {
    var canvas = $("cults");
    var cult_index = cults.indexOf(cult);

    if (canvas.getContext) {
        var ctx = canvas.getContext("2d");

        path = function() {
            ctx.translate(4 + cult_width * cult_index, 495);
            ctx.moveTo(0, 0);
            ctx.lineTo(0, -20);
            ctx.lineTo(cult_width - 4*2, -20);
            ctx.lineTo(cult_width - 4*2, 0);
            ctx.lineTo(0, 0);
        }

        ctx.beginPath();

        ctx.save();
        ctx.scale(2, 2);
        ctx.strokeStyle = "#000";
        ctx.lineWidth = 4;
        path();
        ctx.stroke();
        ctx.restore();

        ctx.save();
        ctx.scale(2, 2);
        ctx.strokeStyle = colors.activeUI;
        ctx.lineWidth = 3;
        path();
        ctx.stroke();
        ctx.restore();
    }
}

function cultClickHandler(fun) {
    return function (event) {
        $("menu").hide();
        var position = $("cults").getBoundingClientRect();
        var x = event.clientX - position.left;
        var y = event.clientY - position.top;
        if (y < 470) { return }
        for (var i = 0; i < 4; ++i) {
            if (x < (i+1) * cult_width) {
                return fun(cults[i], event);
            }
        }
    };
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
    ctx.strokeStyle = contrastColor[color];
    ctx.textAlign = 'center';
    var l = name[0].toUpperCase();
    if (name == 'cultists' || 
        name == 'dragonlords' ||
        name == 'shapeshifters' ||
        name == 'acolytes') {
        l = l.toLowerCase();
    }
    drawText(ctx, l, -1, 14,
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

function renderAction(canvas, name, key, border_color) {
    if (!canvas.getContext) {
        return;
    }

    var ctx = canvas.getContext("2d");

    ctx.save();
    ctx.scale(2, 2);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.translate(2, 2);

    if (state.map[key] && state.map[key].blocked) {
        ctx.fillStyle = '#ccc';
    } else if (state.actions[name] && state.actions[name].dont_block) {
        ctx.fillStyle = '#df0'
    } else {
        ctx.fillStyle = colors.orange;
    }
    ctx.strokeStyle = '#000';

    var edge = 13.5;
    ctx.translate(0.5, 0.5);
    ctx.moveTo(0, 1*edge);
    ctx.lineTo(1*edge, 0);
    ctx.lineTo(2*edge, 0);
    ctx.lineTo(3*edge, 1*edge);
    ctx.lineTo(3*edge, 2*edge);
    ctx.lineTo(2*edge, 3*edge);
    ctx.lineTo(1*edge, 3*edge);
    ctx.lineTo(0, 2*edge);
    ctx.lineTo(0, 1*edge);
    ctx.closePath();

    ctx.fill();

    if (border_color != '#000') {
        ctx.save();
        ctx.lineWidth = 4;
        ctx.stroke();
        ctx.restore();
    }

    ctx.save();
    ctx.strokeStyle = border_color;
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.restore();
 
    var font = "12px Verdana";
    var font_small = "11px Verdana";
    if (!name.startsWith("FAV") && !name.startsWith("BON")) {
        drawText(ctx, name, 5, 52, font);
    }

    ctx.save();
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    var center = 20.5;
    var bottom = 60;

    var ss_cost = "-3PW";

    if (state.options['fire-and-ice-factions/variable_v4']) {
        ss_cost = "-4PW";
    }
    if (state.options['fire-and-ice-factions/variable_v5']) {
        ss_cost = "-5PW";
    }

    var data = {
        "ACT1": function() {
            drawText(ctx, "bridge", center, center, font_small);
            drawText(ctx, "-3PW", center, 60, font);
        },
        "ACT2": function() {
            drawText(ctx, "P", center, center, font);
            drawText(ctx, "-3PW", center, 60, font);
        },
        "ACT3": function() {
            drawText(ctx, "2W", center, center, font);
            drawText(ctx, "-4PW", center, 60, font);
        },
        "ACT4": function() {
            drawText(ctx, "7C", center, center, font);
            drawText(ctx, "-4PW", center, 60, font);
        },
        "ACT5": function() {
            drawText(ctx, "spd", center, center, font);
            drawText(ctx, "-4PW", center, 60, font);
        },
        "ACT6": function() {
            drawText(ctx, "2 spd", center, center, font);
            drawText(ctx, "-6PW", center, 60, font);
        },
        "ACTA": function() {
            drawText(ctx, "2cult", center, center, font);
        },
        "ACTE": function() {
            drawText(ctx, "bridge", center, center, font_small);
            drawText(ctx, "-2W", center, 60, font);
        },
        "ACTN": function() {
            drawText(ctx, "tf", center, center, font);
        },
        "ACTS": function() {
            drawText(ctx, "TP", center, center, font);
        },
        "ACTW": function() {
            drawText(ctx, "D", center, center, font);
        },
        "ACTH1": function() {
            drawText(ctx, "color", center, center, font);
            drawText(ctx, ss_cost, center, 60, font);
        },
        "ACTH2": function() {
            drawText(ctx, "color", center, center, font);
            drawText(ctx, ss_cost, center, 60, font);
            drawText(ctx, "tokens", center, 70, font);
        },
        "BON1": function() {
            drawText(ctx, "spd", center, center, font);
        },
        "BON2": function() {
            drawText(ctx, "cult", center, center, font);
        },
        "FAV6": function() {
            drawText(ctx, "cult", center, center, font);
        }
    };

    data["ACTH3"] = data["ACTH1"];
    data["ACTH4"] = data["ACTH2"];
    data["ACTH5"] = data["ACTH1"];
    data["ACTH6"] = data["ACTH2"];

    if (data[name]) {
        data[name]();
    }

    ctx.restore();

    ctx.restore();
}

function cultStyle(name) {
    if (cult_bgcolor[name]) {
        return "background-color:" + cult_bgcolor[name] + "";
    }

    return "";
}

function cultClass(name) {
    if (cult_bgcolor[name]) {
        return "cult-" + name;
    }

    return "";
}

function insertAction(parent, name, key) {
    var container = new Element('canvas', {
        'id': 'action/' + key, 'class': 'action', 'width': 100, 'height': 170});
    parent.insert(container);
    var canvas = parent.childElements().last();
    renderAction(canvas, name, key, '#000');
    return container;
}

function renderTile(tile, name, record, faction, count) {
    tile.insertTextSpan(name);
    if (state.bonus_coins[name] && state.bonus_coins[name].C) {
        tile.insertTextSpan(" [#{C}c]".interpolate(state.bonus_coins[name]));
    }
    if (count > 1) {
        tile.insertTextSpan("(x" + count + ")");
    }
    tile.insert(new Element("hr"));

    if (!record) {
        return;
    }

    $H(record.gain).each(function (elem, index) {
        var row = new Element("div");
        row.insert(new Element("span", { style: cultStyle(elem.key)}).updateText(elem.value + " " + elem.key));
        tile.insert(row);
    });
    $H(record.vp).each(function (elem, index) {
        var row = new Element("div");       
        row.updateText("#{key} >> #{value} vp".interpolate(elem));
        tile.insert(row);
    });
    $H(record.pass_vp).each(function (elem, index) {
        elem.value = passVpString(elem.value);

        var row = new Element("div");       
        row.updateText("pass-vp:#{key}#{value}".interpolate(elem));
        tile.insert(row);
    });
    if (record.action) {
        insertAction(tile, name, name + "/" + faction);
    }
    $H(record.income).each(function (elem, index) {
        var row = new Element("div");       
        row.updateText("+#{value} #{key}".interpolate(elem));
        tile.insert(row);
    });
    $H(record.special).each(function (elem, index) {
        var row = new Element("div");       
        row.updateText("#{value} #{key}".interpolate(elem));
        tile.insert(row);
    });
}

function passVpString(vps) {
    var stride = vps[1] - vps[0];
    for (var i = 1; i < vps.length; ++i) {
        if (vps[i-1] + stride != vps[i]) {
            stride = null;
            break;
        }
    }
    
    if (stride) {
        return "*" + stride;
    } else {
        return" [" + vps + "]";
    }
}

function renderBonus(div, name, faction) {
    renderTile(div, name, state.bonus_tiles[name], faction, 1);
}

function renderFavor(div, name, faction, count) {
    renderTile(div, name, state.favors[name], faction, count);
}

function renderTown(tile, name, faction, count) {
    if (count != 1) {
        tile.insertTextSpan(name + " (x" + count + ")");
    } else {
        tile.insertTextSpan(name);
    }

    var head = "#{VP} vp".interpolate(state.towns[name].gain);
    if (state.towns[name].gain.KEY != 1) {
        head += ", #{KEY} keys".interpolate(state.towns[name].gain);
    } 
    tile.insert(new Element("div").updateText(head));
    $H(state.towns[name].gain).each(function(elem, index) {
        var key = elem.key;
        var value = elem.value;
        var klass = cultClass(key);

        if (key != "VP" && key != "KEY") {
            var row = new Element("div");
            row.insertTextSpan("#{value} #{key}".interpolate(elem),
                              klass);
            tile.insert(row);
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
        var elem = insertAction(board, name, name);
        if (state.actions[name] &&
            state.actions[name].show_if &&
            !state.factions[faction][state.actions[name].show_if]) {
            elem.hide();
        }
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


function renderTreasury(board, treasury, faction, filter) {
    $H(treasury).sortBy(naturalSortKey).each(function(elem, index) {
        var name = elem.key;
        var value = elem.value;

        if (!filter || filter(name)) {
            renderTreasuryTile(board, faction, name, value);
        }
    });
}

function makeBoard(color, title, info_link, klass, style) {
    var board = new Element('div', {
        'class': klass,
        'style': style
    });
    var bgcolor = colors[color];
    var fgcolor = contrastColor[color];
    var heading = new Element('div', {
        'style': 'padding: 1px 1px 1px 5px; background-color: ' + bgcolor + '; color: ' + fgcolor
    });
    heading.insert(title);
    if (info_link) {
        var elem = new Element('a', { href: info_link,
                                      target: '_blank',
                                      style: 'float: right; color: ' + fgcolor }
                              ).updateText('[info]')
        heading.insert(elem);
    }
    board.insert(heading);

    return board;
}

var cycle = [ "red", "yellow", "brown", "black", "blue", "green", "gray" ]; 

function renderColorCycle(faction, parent) {
    var primaryColor = faction.color;
    var secondaryColor = faction.secondary_color;

    parent.insert(new Element('canvas', {
        'class': 'colorcycle', 'width': 180, 'height': 160}));
    var canvas = parent.childElements().last();
    var startColor = secondaryColor || primaryColor;

    if (!canvas.getContext) {
        return;
    }

    var ctx = canvas.getContext("2d");

    ctx.save()
    ctx.scale(2, 2);
    ctx.translate(40, 41);

    var base = cycle.indexOf(startColor);
    if (base < 0) { base = 0; }

    var homeColor = {}
    $H(state.factions).each(function (elem) {
        var f = elem.value;

        if (f == faction) {
            return;
        }
        if (f.locked_terrain) {
            return;
        }
        homeColor[f.color] = 1;
    });

    for (var i = 0; i < 7; ++i) {
        var terrain = cycle[(base + i) % 7];

        ctx.save()
        if (i == 0 && secondaryColor && primaryColor != 'ice') {
            ctx.lineWidth = 3;
        }

        var size = 10;
        if ((faction.name == "dragonlords" ||
             faction.name == "acolytes" ||
             faction.name == "shapeshifters") &&
            homeColor[terrain]) {
            size = 7.5;
        }            

        var angle = (Math.PI * 2 / 7) * i - Math.PI / 2;
        ctx.translate(30 * Math.cos(angle), 30 * Math.sin(angle));

        if (!faction.locked_terrain ||
            !faction.locked_terrain[terrain]) {
            ctx.beginPath();
            ctx.arc(0, 0, size, Math.PI * 2, 0, false);

            ctx.fillStyle = bgcolors[terrain];
            ctx.fill();
            
            ctx.stroke();

            drawColorSymbol(ctx, terrain, 0, 0);
        }

        ctx.restore();
    }

    if (secondaryColor) {
        ctx.save();
        if (primaryColor == "ice") {
            ctx.translate(0, -9);
        }

        ctx.beginPath();
        ctx.arc(0, 0, 10, Math.PI * 2, 0, false);

        ctx.fillStyle = bgcolors[primaryColor];
        ctx.fill();

        ctx.stroke();

        drawColorSymbol(ctx, primaryColor, 0, 0);

        ctx.restore();
    }

    ctx.restore();
}

function rowFromArray(array, style) {
    var tr = new Element("tr", {'style': style});
    array.each(function(elem) {
        if (elem instanceof Element) {
            tr.insert(new Element("td").insert(elem));
        } else {
            tr.insert(new Element("td").updateText(elem));
        }
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
    $("factions").clearContent();

    var order = state.order.concat([]);
    for (var i = order.size(); i < state.players.size(); ++i) {
        var pseudo_faction = "player" + (i+1);
        order.push(pseudo_faction);
        state.factions[pseudo_faction] = {
            display: "Player " + (i+1),
            username: state.players[i].username,
            player: state.players[i].displayname || state.players[i].name,
            color: 'player',
            placeholder: true,
            start_player: i == 0,
            registered: state.players[i].username != null
        };
    }

    if (currentFaction && order.indexOf(currentFaction) >= 0) {
        while (order[0] != currentFaction) {
            order.push(order.shift());
        }
    }

    order.each(function(name) {
        drawFaction(name);
    });

   
    var pool = makeBoard("orange", makeTextSpan("Pool"), '', 'pool');
    renderTreasury(pool, state.pool, 'pool',
                   function (tile) { return !tile.match(/^ACT/) } );
    $("shared-actions").clearContent();
    renderTreasury($("shared-actions"), state.pool, '',
                   function (tile) { return tile.match(/^ACT/) } );
    $("factions").insert(pool);
}

function drawFaction(name) {
    var faction = state.factions[name];
    var color = faction.color;
    var title = factionDisplayName(faction);

    var style = 'float: left; margin-right: 20px; ';
    if (faction.passed) {
        style += 'opacity: 0.5';
        title = new Element("span").insert(title).insert(
            makeTextSpan(", passed"));
    }
    if (faction.dropped) {
        style += 'opacity: 0.25';
        title = new Element("span").insert(title).insert(
            makeTextSpan(", dropped"));
    }

    if (faction.start_player) {
        title = new Element("span").insert(title).insert(
            makeTextSpan(", start player"));
    }

    var container = new Element('div', { 'class': 'faction-board' });
    var info_link = '';
    if (faction.faction_board_id) {
        info_link = 'http://terra.snellman.net/stc/boards/' + faction.name + '.jpg';
    } else {
        info_link = '/factioninfo/#' + faction.name;
    }

    var board = makeBoard(color, title, info_link, '', style);
    container.insert(board);

    if (!faction.placeholder) {
        drawRealFaction(faction, board);
    }

    renderColorCycle(faction, container);
    renderTreasury(container, faction, name);
    
    $("factions").insert(container);
}

function makeToggleLink(text, fun) {
    var link = new Element("a", {'href': 'javascript:'});
    link.updateText(text);
    link.onclick = fun;
    return link;
}

function drawRealFaction(faction, board) {
    var name = faction.name;

    var info = new Element('div', {'class': 'faction-info' });
    board.insert(info);

    if (faction.dummy) { return }

    var vp_id = faction.name + "/vp";
    if (faction.vp_source) {
        var vp_breakdown = new Element('table', {'id': vp_id,
                                                 'style': 'display: none',
                                                 'class': 'vp-breakdown'});
        vp_breakdown.insert(new Element("tr").insert(
            new Element("td", { colspan: 2 }).insert(
                new Element("b").updateText("VP breakdown"))));
        $H(faction.vp_source).sortBy(function(a) { return -a.value}).each(function(record) {
            var row = new Element("tr");
            row.insert(new Element("td").updateText(record.key));
            row.insert(new Element("td").updateText(record.value));
            vp_breakdown.insert(row);
        });
        board.insert(vp_breakdown);
    }

    {
        var resources = new Element("div");
        resources.insertTextSpan("#{C} c, ".interpolate(faction));
        resources.insertTextSpan("#{W} w, ".interpolate(faction));

        resources.insertTextSpan(faction.P);
        resources.insertTextSpan("/" + faction.MAX_P,
                                 'faction-info-unimportant');
        resources.insertTextSpan(" p, ");

        var link = makeToggleLink(faction.VP,
                                  function() { toggleVP(vp_id); });
        resources.insert(link);
        resources.insertTextSpan(" vp, ");
        resources.insertTextSpan("#{P1}/#{P2}/#{P3} pw".interpolate(faction));
        info.insert(resources);
    }

    var levels = new Element("div");

    if (faction.dig &&
        faction.dig.max_level > 0) {
        if (levels.innerHTML != '') {
            levels.insertTextSpan(", ");
        }
        levels.insertTextSpan("dig level " + faction.dig.level);
        levels.insertTextSpan("/" + faction.dig.max_level,
                                   'faction-info-unimportant');
    }

    if (faction.teleport) {
        if (levels.innerHTML != '') {
            levels.insertTextSpan(", ");
        }
        var range = faction[faction.teleport.type + "_range"];
        var max_range = faction[faction.teleport.type + "_max_range"];
        levels.insertTextSpan("range " + range);
        levels.insertTextSpan("/" + max_range,
                              'faction-info-unimportant');
    }

    if (faction.ship.max_level > 0) {
        if (levels.innerHTML != '') {
            levels.insertTextSpan(", ");
        }
        levels.insertTextSpan("ship level " + faction.ship.level);
        levels.insertTextSpan("/" + faction.ship.max_level + " ",
                              'faction-info-unimportant');
        if (faction.BON4 > 0) {
            levels.insertTextSpan("(+1)",
                                  faction.passed ? 'faction-info-not-applicable' : '');
        }
    }

    if (faction.ALLOW_SHAPESHIFT != null &&
        faction.ALLOW_SHAPESHIFT < 10) {
        if (levels.innerHTML != '') {
            levels.insertTextSpan(", ");
        }
        levels.insertTextSpan("shapeshifts " + faction.ALLOW_SHAPESHIFT);
    }

    info.insert(levels);
    info.insert(new Element("div"));

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
        var klass = '';
        if (record.level == record.max_level && record.max_level > 3) {
            klass = 'faction-info-building-max';
        }
        count.push(makeTextSpan(text, klass));
        cost.push("#{advance_cost.C}c, #{advance_cost.W}w".interpolate(record));
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
                income.push("+" + income_delta.join(", "));
            } else {
                income.push("");
            }
        }
    });

    var head_row = rowFromArray(b, '');
    head_row.insert(new Element("td").insert(
        makeToggleLink("+", function() { toggleBuildings(buildings_id); })))
    buildings.insert(head_row);
    buildings.insert(rowFromArray(count, ''));
    buildings.insert(rowFromArray(cost, 'display: none'));
    buildings.insert(rowFromArray(income, 'display: none'));

    var income_id = "income-" + name;
    var income = new Element('table', {'class': 'income-table', 'id': income_id});
    info.insert(income);

    if (faction.income) {
	var row = new Element('tr');
        row.insert(new Element("td").updateText("Income:"));
        row.insert(new Element("td").updateText("total"));
        row.insert(new Element("td").updateText(faction.income.C + " c"));
        row.insert(new Element("td").updateText(faction.income.W + " w"));

        var P_class = '';
        if (faction.income.P > faction.MAX_P - faction.P) {
            P_class = 'faction-info-income-overflow';
        }
        row.insert(new Element("td").insert(
            makeTextSpan(faction.income.P + " p", P_class)));

        var PW_class = '';
        if (faction.income.PW > faction.P1 * 2 + faction.P2) {
            PW_class = 'faction-info-income-overflow';
        }
        row.insert(new Element("td").insert(
            makeTextSpan(faction.income.PW + " pw", PW_class)));

	row.insert(new Element('td').insert(
            makeToggleLink("+", function() { toggleIncome(income_id); })));
        income.insert(row);
    }

    if (faction.income_breakdown) {
        income.insert(Element('tr', {'style': 'display: none'}).insert(
            new Element("td", { colspan: 6 }).insert(
                new Element("hr"))));
        $H(faction.income_breakdown).each(function(elem, ind) {
            if (!elem.value) {
                return;
            }

            var row = new Element('tr', {'style': 'display: none'});
            row.insert(new Element("td"));
            row.insert(new Element("td").updateText(elem.key));
            row.insert(new Element("td").updateText(elem.value.C));
            row.insert(new Element("td").updateText(elem.value.W));
            row.insert(new Element("td").updateText(elem.value.P));
            row.insert(new Element("td").updateText(elem.value.PW));
            income.insert(row);
        });
    }

    if (faction.vp_projection) {
        var vp_proj_id = "vp-projection-" + name;
        var vp_proj = new Element('table', {'class': 'income-table', 'id': vp_proj_id});
        info.insert(vp_proj);
        {
	    var row = new Element('tr');
            row.insert(new Element('td').updateText('VP projection:'));
            row.insert(new Element('td').updateText('total'));
            row.insert(new Element('td').updateText(faction.vp_projection.total));
            row.insert(new Element('td').insert(
                makeToggleLink("+", function() { toggleIncome(vp_proj_id) })));
            vp_proj.insert(row);
        }

        vp_proj.insert(Element('tr', {'style': 'display: none'}).insert(
            new Element("td", { colspan: 3 }).insert(
                new Element("hr"))));
        $H(faction.vp_projection).each(function(elem, ind) {
            if (!elem.value || elem.key == "total") {
                return;
            }

            var row = new Element('tr', {'style': 'display: none'});
            row.insert(new Element("td"));
            row.insert(new Element("td").updateText(elem.key));
            row.insert(new Element("td").updateText(elem.value));
            vp_proj.insert(row);
        });            
    }
}

function drawLedger(draw_full_ledger) {
    var ledger = $("ledger");
    ledger.clearContent();
    var recent_moves = [];

    var small_ledger_rows = 20;
    var count = state.ledger.size();
    if (count < small_ledger_rows) {
        draw_full_ledger = true;
    }

    if (!draw_full_ledger) {
        var row = new Element("tr");
        row.insert(new Element("td", { colspan: 14 }));

        var col = new Element("td");
        row.insert(col);
        col.insertTextSpan("Showing only last 20 lines of the game log. ",
                           "bold");
        col.insert(new Element("br"));
        var button = new Element("button").updateText("Load full log");
        button.onclick = function() { drawLedger(true); }
        col.insert(button);

        ledger.insert(row);
    }

    state.ledger.each(function(record, index) {
        if (!draw_full_ledger && index < count - small_ledger_rows) {
            return;
        }
        if (record.comment) {
            var row = new Element("tr", { id: commentAnchor(record.comment) });
            row.insert(new Element("td"));
            row.insert(new Element("td", { colspan: 13,
                                           style: "font-weight: bold" }).
                       updateText(record.comment));
            row.insert(new Element("td").
                       insert(new Element("a", { href: showHistory(index + 1) }).updateText("show history")));

            // var move_entry = new Element("tr");
            // move_entry.insert(new Element("td", {"colspan": 2, "style": "font-weight: bold"}).updateText(record.comment));
            // $("recent_moves").insert(move_entry);
            ledger.insert(row);
        } else {
            record.bg = colors[state.factions[record.faction].color];
            record.fg = (record.bg == '#000000' ? '#ccc' : '#000');

            if (currentFaction) {
                if (record.faction == currentFaction &&
                    !/^(leech|decline)/i.match(record.commands)) {
                    recent_moves = [];
                }
                recent_moves.push(record);
            }

            var row = new Element("tr");
            row.insert(new Element("td", { style: 'background-color:#{bg}; color: #{fg}'.interpolate(record) }).updateText(record.faction));

            ["VP", "C", "W", "P", "PW", "CULT"].each(function(key) {
                var elem = record[key];
                var type = (key == "CULT" ? '' : key);
                var delta = elem.delta;

                if (!delta) {
                    delta = '';
                } else if (delta > 0) {
                    delta = "+" + delta;
                }
                row.insert(new Element("td", { 'class': 'ledger-delta' }).updateText(delta));
                row.insert(new Element("td", { 'class': 'ledger-value' }).updateText(elem.value + " " + type));
            });

            var leechCell = new Element("td", { 'class': 'ledger-delta' });
            $H(record.leech).each(function (elem, index) {
                elem.color = contrastColor[elem.key];
                elem.key = colors[elem.key];
                var leech = new Element("span", { style: 'color: #{color}; background-color: #{key}'.interpolate(elem) });
                leech.updateText(elem.value);
                leechCell.insert(leech);
                leechCell.insertTextSpan("\u00a0");
            });
            row.insert(leechCell);
            row.insert(new Element("td", { 'class': 'ledger-delta' }).updateText(record.commands));

            ledger.insert(row);
            if (record.warning) {
                var warnRow = new Element("tr");
                warnRow.insert(new Element("td", { colspan: 14 }));
                warnRow.insert(new Element("td").insert(
                    makeTextSpan(record.warning, 'warning')));
                ledger.insert(warnRow);
            }
        }
    });

    return recent_moves;
}

function drawRecentMoves(recent_moves) {
    var container = $("recent_moves");
    if (!container) {
        return;
    }
    container.clearContent();
    recent_moves.each(function (record) {
        var move_entry = new Element("tr");
        move_entry.insert(new Element("td").insert(
            coloredFactionSpan(record.faction)));
        move_entry.insert(new Element("td").updateText(record.commands));
        container.insert(move_entry);
    });
}

function showHistory(row) {
    var loc = document.location.href;
    loc = loc.replace(/\/max-row=.*/, '');
    return "/game/" + TM.params.game + "/max-row=" + row;
}

function drawScoringTiles() {
    var container = $("scoring");
    container.clearContent();

    state.score_tiles.each(function(record, index) {
        var style = '';
        if (index == (state.round - 1)) {
            style = 'background-color: #d0ffd0';
        } else if (index < state.round) {
            style = 'opacity: 0.5';
        }
        var tile = new Element('div', {'class': 'scoring', 'style': style});
        tile.insert(new Element('div', {'style': 'float: right; border-style: solid; border-width: 1px; '}).updateText("r" + (index + 1)));
        
        {
            var row = new Element("div");
            row.insert(new Element("div", { "class": "scoring-head" }).updateText("vp:"));
            row.insert(new Element("div").updateText(record.vp_display));
            tile.insert(row);
        }

	if (index < 5) {
            var style = cultStyle(record.cult);
            var row = new Element('div');
            row.insert(new Element("div", { "class": "scoring-head" }).updateText("income:"));
            row.insert(new Element("div").insert(
                new Element("span", { style: style }).updateText(
                    record.income_display)));
            tile.insert(row);
	}
        container.insert(tile);
    });

    {
        var tile = new Element('div', {'class': 'final-scoring' });
        var table = new Element('table', {'class': 'final-scoring'});
        tile.insert(table);
        table.insert(new Element("tr").insert(
            new Element("td", {"style": "font-weight: bold", "colspan": 2}).updateText(
                "Final vp")));
        $H(state.final_scoring).sortBy(naturalSortKey).each(function (elem) {
            var type = elem.value.label || elem.key;
            var desc = elem.value.description;
            var points = elem.value.points;
            var row = new Element("tr");
            var label = new Element("span", { "title": desc });
            label.updateText(type);
            row.insert(new Element("td").insert(label));
            row.insert(new Element("td").updateText(points.join('/')));
            table.insert(row);
        });
        container.insert(tile);
    }
}

function drawTurnOrder() {
    if (!state.options['variable-turn-order']) {
        return;
    }

    var container = $('turn-order');
    var passed = new Element("div", {'class': 'turn-order-block'}).insert(new Element("b").updateText("Passed"));
    var active = new Element("div", {'class': 'turn-order-block'}).insert(new Element("b").updateText("Active"));

    state.order.each(function (faction_name) {
        var faction = state.factions[faction_name];
        var parent = faction.passed ? passed : active;

        parent.insert(new Element('canvas', { 'width': 30, 'height': 30}));
        var canvas = parent.childElements().last();
        if (canvas.getContext) {
            canvas.width = canvas.width;
            var ctx = canvas.getContext("2d");
            ctx.translate(15, 0);
            ctx.scale(1.5, 1.5);
            drawCultMarker(ctx, faction.color, faction.name, false);
        }
    });

    container.innerHTML = '';
    container.insert(active);
    container.insert(passed);
}

function coloredFactionSpan(faction_name) {
    record = {};
    if (state.factions[faction_name]) {
        record.bg = colors[state.factions[faction_name].color];
        record.fg = (record.bg == '#000000' ? '#ccc' : '#000');
        record.display = factionDisplayName(state.factions[faction_name]);
    } else {
        var display = '';
        var players = {};
        state.players.each(function (value, index) {
            players["player" + (index + 1)] = (value.displayname || value.name);
        });
        if (players[faction_name]) {
            display = faction_name + " (" + players[faction_name] + ")"
        } else {
            display = faction_name;
        }

        return makeTextSpan(display);
    }

    var style = "background-color:#{bg}; color: #{fg}".interpolate(record);
    return new Element("span", { style: style }).insert(record.display);
}

function playerLink(player, display) {
    var url = '/player/' + player;
    var link = new Element("a", { style: 'color: inherit',
                                  href: url });
    link.updateText(display);
    return link;
}

function factionDisplayName(faction, fg) {
    var res = new Element("span");
    res.insertTextSpan(faction.display + " ");
    if (faction.registered) {
        res.insert(playerLink(faction.username,
                              "(" + faction.player + ")"));                
    } else {
        res.insertTextSpan(faction.player);
    }
    return res;
}

var allowSaving = false;
var map_click_handlers = {};
var cult_click_handlers = {};

function menuClickHandler(title, loc, funs) {
    funs = $H(funs);
    var select = function(loc, event) {
        var menu = $("menu");
        menu.hide();
        menu.clearContent();
        var head = new Element("div", {"style": "width: 100%"});
        head.insert(new Element("div", {"style": "white-space: nowrap"}).updateText(loc + ": " + title));
        menu.insert(head);

        $H(funs).each(function (elem) {
            var type = elem.key;
            var fun = elem.value.fun;
            var label = " " + elem.value.label;

            var button = new Element("button").updateText(type);
            button.onclick = function() {
                menu.hide();
                fun(loc, type);
            }
            menu.insert(new Element("div", {"class": "menu-item"}).insert(button).insertTextSpan(label));
        });


        var cancel = new Element("button").updateText("Cancel");
        menu.insert(new Element("div", {"class": "menu-item"}).insert(cancel));
        cancel.onclick = function () { menu.hide(); }

        menu.style.left = (event.pageX + 10) + "px";
        menu.style.top = event.pageY + 15 + "px";

        menu.show();
    }

    return select;
}

function addMapClickHandler(title, loc, funs) {
    if (false && funs.size() == 1) {
        var elem = funs.entries()[0];
        map_click_handlers[loc] = function(loc, event) {
            elem[1](loc, elem[0]);
        };
    } else {
        map_click_handlers[loc] = menuClickHandler(title, loc, funs);
    }
    drawActiveHexBorder(state.map[loc]);
}

function addCultClickHandler(title, cult, funs) {
    cult_click_handlers[cult] = menuClickHandler(title, cult, funs);
    drawActiveCultBorder(cult);
}

function currentPlayerShouldMove() {
    var ret = false;
    if (currentFaction) {
        state.action_required.each(function(record, index) {
            if (record.faction == currentFaction ||
                record.player_index == currentFaction) {
                ret = true;
            }
        });
    }

    return ret;
}

function drawActionRequired() {
    var parent = $("action_required");

    if (!parent) {
        return;
    }

    parent.clearContent();

    var needMoveEntry = false;

    allowSaving = true;

    map_click_handlers = {};
    cult_click_handlers = {};

    $("map").onclick = hexClickHandler(function(hex, event) {
        if (map_click_handlers[hex] && moveEntryEnabled()) {
            map_click_handlers[hex](hex, event);
        }
    });

    $("cults").onclick = cultClickHandler(function(cult, event) {
        if (cult_click_handlers[cult] && moveEntryEnabled()) {
            cult_click_handlers[cult](cult, event);
        }
    });

    state.action_required.each(function(record, index) {
        var pretty_text = '';
        var pretty_elem = null;

        if (record.type == 'full') {
            pretty_text = 'should take an action';
            if (state.factions[record.faction].can_leech) {
                pretty_text += ' after power leeching decision';
            }
        } else if (record.type == 'leech') {
            pretty_elem = new Element("span");
            pretty_elem.insertTextSpan('may gain #{amount} power from '.interpolate(record));
            pretty_elem.insert(coloredFactionSpan(record.from_faction));
            if (record.actual != record.amount) {
                pretty_elem.insertTextSpan(" (actually #{actual} power)".interpolate(record));
            }
            state.factions[record.faction].can_leech = true;            
        } else if (record.type == 'transform') {
            if (record.amount == 1) {
                pretty_text = 'may use a spade (click on map to transform)'.interpolate(record);
            } else if (record.amount == null) {
                pretty_text = 'may transform a space (click on map)'.interpolate(record);
            } else {
                pretty_text = 'may use #{amount} spades (click on map to transform)'.interpolate(record);
            }
        } else if (record.type == 'convert') {
            if (record.amount == 1) {
                pretty_text = 'may convert 1 #{from} to #{to}'.interpolate(record);
            } else {
                pretty_text = 'may convert #{amount} #{from} to #{to}'.interpolate(record);
            }
        } else if (record.type == 'cult') {
            if (record.amount == 1) {
                pretty_text = 'may advance 1 step on a cult track'.interpolate(record);
            } else {
                pretty_text = 'may advance #{amount} steps on a cult track'.interpolate(record);
            }
        } else if (record.type == 'lose-cult') {
            if (record.amount == 1) {
                pretty_text = 'must lose 1 step on a cult track'.interpolate(record);
            } else {
                pretty_text = 'must lose #{amount} steps on a cult track'.interpolate(record);
            }
        } else if (record.type == 'gain-token') {
            pretty_text = 'may gain 1 power token for 1 #{from}'.interpolate(record);
        }else if (record.type == 'town') {
            if (record.amount == 1) {
                pretty_text = 'may form a town'.interpolate(record);
            } else {
                pretty_text = 'may form #{amount} towns'.interpolate(record);
            }
        } else if (record.type == 'bridge') {
            pretty_text = 'may place a bridge (click on map)'.interpolate(record);
        } else if (record.type == 'favor') {
            if (record.amount == 1) {
                pretty_text = 'must take a favor tile'.interpolate(record);
            } else {
                pretty_text = 'must take #{amount} favor tiles'.interpolate(record);
            }
        } else if (record.type == 'dwelling') {
            pretty_text = 'should place a dwelling (choose option or click on map)';
        } else if (record.type == 'upgrade') {
            pretty_text = 'may place a free #{to_building} upgrade (choose option or click on map)'.interpolate(record);
        } else if (record.type == 'bonus') {
            pretty_text = 'should pick a bonus tile';
        } else if (record.type == 'gameover') {
            pretty_elem = new Element("div");
            record.reason = record.aborted ? "aborted" : "over";
            if (state.metadata) {
                record.age = seconds_to_pretty_time(state.metadata.time_since_update);
                pretty_elem.insertTextSpan("The game is #{reason} (finished #{age} ago)".interpolate(record));
            } else {
                pretty_elem.insertTextSpan("The game is #{reason}".interpolate(record));
            }
            var table = new Element("table");
            $H(state.factions).sortBy(function(a) { return -a.value.VP }).each(function(elem) {
                var row = new Element("tr");
                row.insert(new Element("td").insert(coloredFactionSpan(elem.key)));
                row.insert(new Element("td").updateText(" " + elem.value.VP));
                table.insert(row);
            });
            pretty_elem.insert(table);
        } else if (record.type == 'faction') {
            pretty_text = '#{player} should pick a faction'.interpolate(record);
        } else if (record.type == 'pick-color') {
            pretty_text = 'must pick a color'.interpolate(record);
         } else if (record.type == 'unlock-terrain') {
             if (record.count == 1) {
                 pretty_text = 'may unlock a new terrain type'.interpolate(record);
             } else {
                 pretty_text = 'may unlock #{count} new terrain types'.interpolate(record);
             }
         } else if (record.type == 'not-started') {
            pretty_text = "Game hasn't started yet, #{player_count}/#{wanted_player_count} players have joined.".interpolate(record);
        } else if (record.type == 'planning') {
            pretty_text = 'are planning';
        } else {
            pretty_text = '?';
        }

        var faction_span = new Element("span");

	if (record.faction) {
            record.faction_span = coloredFactionSpan(record.faction);
	}

        var row = new Element("div", {'style': 'margin: 3px'});
        row.insert(record.faction_span);
        row.insertTextSpan(" ");
        if (pretty_elem) {
            row.insert(pretty_elem);
        } else {
            row.insertTextSpan(pretty_text);
        }
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

    if ($("data_entry").innerHTML == "") {
        var selectTab = null;

        $("data_entry").insert("<div id='data_entry_tabs'></div>");

        if (currentFaction) {
            selectTab = "move";
            $("data_entry_tabs").insert("<button onclick='dataEntrySelect(\"move\"); updateMovePicker();' id='data_entry_tab_move' class='tab' accesskey='m'>Moves</button>");
        }

        if (currentFaction) {
            $("data_entry_tabs").insert("<button onclick='initPlanIfNeeded(); dataEntrySelect(\"planning\")' id='data_entry_tab_planning' class='tab' accesskey='p'>Planning</button>");
        }

        if (currentFaction) {
            $("data_entry_tabs").insert("<button onclick='dataEntrySelect(\"recent\")' id='data_entry_tab_recent' class='tab' accesskey='r'>Recent Moves</button>");
        }

        if (currentFaction ||
            (loggedIn() && loggedIn()[1] == "jsnell")) {
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

        if (state.metadata) {
            $("data_entry_tabs").insert("<button onclick='updateInfoTab(); dataEntrySelect(\"info\")' id='data_entry_tab_info' class='tab'>Info</button>");
        }

        $("data_entry").insert("<div id='move_entry' class='tab_content'></div>");
        $("data_entry").insert("<div id='planning_entry' class='tab_content'></div>");
        $("data_entry").insert("<div id='recent_entry' class='tab_content'></div>");
        $("data_entry").insert("<div id='chat_entry' class='tab_content'></div>");
        $("data_entry").insert("<div id='info_entry' class='tab_content'></div>");

        if (selectTab) {
            dataEntrySelect(selectTab);
        } else {
            $$("#data_entry div.tab_content").each(function(tab) {
                tab.hide();
            });
        }
    }

    if ($("planning_entry") && $("planning_entry").innerHTML == "") {
        var input = new Element("textarea", {"id": "planning_entry_input",
                                             "style": "font-family: monospace; width: 70ex; height: 12em;" } );
        $("planning_entry").insert(input);
        $("planning_entry").insert("<div style='padding-left: 2em'><button id='planning_entry_action' onclick='javascript:previewPlan()'>Show Result</button><button id='planning_entry_action' onclick='javascript:savePlan()'>Save Plan</button><br><div id='planning_entry_explanation'>Use this entry box to leave notes for yourself, or to plan your coming moves using the same input format as for normal play. View the effects of the plan with 'show result' or save the plan / notes for later with 'save plan'.</div></div>");
    }

    if ($("recent_entry") && $("recent_entry").innerHTML == "") {
        var recent = new Element("table", { "id": "recent_moves" });
        $("recent_entry").insert(recent);
    }

    if ($("chat_entry") && $("chat_entry").innerHTML == "") {
        $("chat_entry").insert(new Element("table", {"id": "chat_messages" }));
        var input = new Element("textarea", {"id": "chat_entry_input",
                                             "style": "font-family: monospace; width: 60ex; height: 5em;" } );
        $("chat_entry").insert(input);
        $("chat_entry").insert(new Element("br"));
        $("chat_entry").insert(new Element("button", {"id": "chat_entry_submit", "onclick": "javascript:sendChat()"}).updateText("Send"));
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
    var count = 0;
    $H(state.pool).sortBy(naturalSortKey).each(function(tile) {
        if (tile.value < 1 || !tile.key.startsWith(prefix)) {
            return;
        }

        if (prefix == "FAV" &&
            state.factions[currentFaction] &&
            state.factions[currentFaction][tile.key] > 0) {
            return;
        }

        var container = new Element("div", {"style": "display: inline-block"});

        var button = new Element("button").updateText(tile.key);
        button.onclick = function() {
            gainResource(index, '', tile.key, id);
        };
        container.insert(button);
        container.insert(new Element("br"));

        renderTreasuryTile(container, currentFaction,
                           tile.key, state.pool[tile.key]);
        
        div.insert(container);
        ++count;
    });
    if (prefix == "FAV" && count == 0) {
        var container = new Element("div", {"style": "display: inline-block"});
        div.insert(container);
        container.insert(makeDeclineButton("GAIN_FAVOR", 1));
    }
    parent.insert(div);
}

function makeDeclineButton(resource, amount) {
    var button = new Element("button").updateText("Decline");
    button.onclick = function() {
        if (amount == 1) {
            appendCommand("-" + resource);
        } else if (amount > 1) {
            appendCommand("-" + amount + resource);
        }
    };
    return button;
}

function addDeclineButton(parent, index, resource, amount) {
    var div = new Element("div", { "id": "leech-" + index + "-0",
                                   "style": "padding-left: 2em" });
    div.insert(makeDeclineButton(resource, amount));
    parent.insert(div);
}

function addFactionInput(parent, record, index) {
    var faction = state.factions[currentFaction];
    if (record.type == "leech") {
        if (faction.leech_record_output) {
            return;
        }
        faction.leech_record_output = true;
        var div = new Element("div", { "id": "leech-" + index,
                                       "style": "padding-left: 2em" });
        var accept = new Element("button").updateText("Accept");
        var decline = new Element("button").updateText("Decline");
        accept.onclick = function() { acceptLeech(index); };
        decline.onclick = function() { declineLeech(index); };
        div.insert(accept);
        div.insertTextSpan(" ");
        div.insert(decline);
        if (index != 0) {
            var wait = new Element("button").updateText("Wait");
            wait.onclick = function() { appendCommand("wait"); };
            div.insertTextSpan(" ");
            div.insert(wait);
        }
        parent.insert(div);
    }
    if (record.type == "cult") {
        var amount = record.amount;
        var div = new Element("div", { "id": "leech-" + index + "-0",
                                       "style": "padding-left: 2em" });
        // If the cult steps can be split, take them one at a time.
        if (!faction.CULTS_ON_SAME_TRACK && amount > 1) {
            amount = 1;
        }
        cults.each(function(cult) {
            var button = new Element("button",
                                     {"style": cultStyle(cult)}).
                updateText(cult.capitalize());
            button.onclick = function() {
                gainResource(index, amount == 1 ? '' : amount, cult, 0);
            };
            div.insert(button);                                               
        });
        parent.insert(div);
    }
    if (record.type == "lose-cult") {
        var amount = record.amount;
        var div = new Element("div", { "id": "leech-" + index + "-0",
                                       "style": "padding-left: 2em" });
        cults.each(function(cult) {
            if (faction[cult] < amount) {
                return;
            }
            var button = new Element("button",
                                     {"style": cultStyle(cult)}).
                updateText(cult.capitalize());
            button.onclick = function() {
                gainResource(index, -amount, cult, 0);
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
        addTakeTileButtons(parent, index, "BON", 0);
    }
    if (record.type == "transform") {
        if (faction.SPADE > 0 && !faction.disable_spade_decline) {
            addDeclineButton(parent, index, "SPADE", faction.SPADE);
        }
        if (faction.FREE_TF > 0) {
            addDeclineButton(parent, index, "FREE_TF", faction.FREE_TF);
        }
        if (faction.force_dismiss_spades) {
            return;
        }

        $H(faction.reachable_tf_locations).each(function (elem) {
            var hex = elem.key;
            var menu = {};
            elem.value.each(function (tf) {
                if (canAfford(faction, [tf.cost])) {
                    var cost_str = effectString([tf.cost], [tf.gain])
                    menu["to " + tf.to_color] = {
                        "fun": function (loc) {
                            appendAndPreview("transform " + loc + " to " + tf.to_color);
                        },
                        "label": cost_str
                    };
                }
                if (tf.to_color == faction.color &&
                    !(faction.SPADE - tf.cost.SPADE) &&
                    faction.allowed_sub_actions.build &&
                    faction.buildings.D.level < faction.buildings.D.max_level) {
                    var dwelling_cost = faction.buildings["D"].advance_cost;
                    var dwelling_gain = computeBuildingEffect(faction, 'D');
                    var can_afford = canAfford(faction, 
                                               [tf.cost, dwelling_cost]);
                    if (can_afford) {
                        cost_str = effectString([tf.cost, dwelling_cost],
                                                [tf.gain].concat(dwelling_gain));
                        menu["build"] = {
                            "fun": function (loc) {
                                appendAndPreview("build " + loc);
                            },
                            "label": cost_str
                        };
                    }
                }
            });
            if ($H(menu).size() > 0) {
                addMapClickHandler("Transform", hex, menu);
            }
        })
    }
    if (record.type == "convert") {
        var div = new Element("div", { "id": "leech-" + index + "-0",
                                       "style": "padding-left: 2em" });
        var action = "CONVERT_#{from}_TO_#{to}".interpolate(record);
        for (var i = 1; i <= record.amount && i <= faction[record.from]; ++i) {
            var button = new Element("button").updateText("Convert " + i);
            var cmd = "convert " + i + record.from + " to " + i + record.to;
            button.onclick = function(cmd) {
                return function() {
                    appendAndPreview(cmd);
                };
            }(cmd);
            div.insert(button);
        }

        div.insert(makeDeclineButton(action,
                                     faction[action]));
        parent.insert(div);
    }
    if (record.type == "gain-token") {
        var div = new Element("div", { "id": "leech-" + index + "-0",
                                       "style": "padding-left: 2em" });
        var action = "GAIN_#{to}_FOR_#{from}".interpolate(record);

        var button = new Element("button").updateText("Gain token");
        var cmd = "gain #{to} for #{from}".interpolate(record);
        button.onclick = function(cmd) {
            return function() {
                appendAndPreview(cmd);
            };
        }(cmd);
        div.insert(button);

        div.insert(makeDeclineButton(action,
                                     faction[action]));
        parent.insert(div);
    }
    if (record.type == "faction") {
        var div = new Element("div", { "id": "leech-" + index + "-0",
                                       "style": "padding-left: 2em" });
        var table = new Element("table"); div.insert(table);
        var row = new Element("tr"); table.insert(row);
        var cell1 = new Element("td", {"valign": "top"}); row.insert(cell1);
        var cell2 = new Element("td", {"valign": "top"}); row.insert(cell2);
        var boards = { "green": ["witches", "auren"],
                       "blue": ["mermaids", "swarmlings" ],
                       "black": ["darklings", "alchemists"],
                       "brown": ["halflings", "cultists"], 
                       "yellow": ["nomads", "fakirs"],
                       "red": ["giants", "chaosmagicians"],
                       "gray": ["dwarves", "engineers"],
                       "ice": ["icemaidens", "yetis"],
                       "volcano": ["dragonlords", "acolytes"],
                       "variable": ["shapeshifters", "riverwalkers"],
                     };

        $H(state.factions).each(function(used_faction) {
            if (boards[used_faction.value.color]) {
                boards[used_faction.value.color] = [];
            }
            if (boards[used_faction.value.secondary_color]) {
                boards[used_faction.value.secondary_color] = [];
            }
            if (boards[used_faction.value.board]) {
                boards[used_faction.value.board] = [];
            }
        });

        $H(boards).each(function(board) {
            var cell = cell1;
            if (board.key == "ice" || board.key == "volcano" || board.key == "variable") {
                cell = cell2;
            }
            var color_factions = board.value.sort();
            if (color_factions.size() == 0) {
                var notAvailable = new Element("button").updateText(
                    "Already taken");
                notAvailable.style.backgroundColor = bgcolors[board.key];
                notAvailable.style.color = contrastColor[board.key];
                notAvailable.disabled = true;
                cell.insert(notAvailable);
            } else {
                color_factions.each(function(faction) {
                    if (!state.available_factions[faction]) {
                        return;
                    }
                    var label = factionPrettyName[faction];
                    if (state.vp_setup && state.vp_setup[faction]) {
                        label += " [" + state.vp_setup[faction] + " vp]";
                    }
                    var button = new Element("button").updateText(label);
                    button.onclick = function() {
                        appendCommand("setup " + faction + "\n");
                    };
                    setFactionStyleForElement(button, faction);
                    cell.insert(button);
                });
            }
            if (state.faction_variant_help && cell == cell2) {
                cell.insert(new Element("a", {
                    "href": state.faction_variant_help
                }).updateText("[info]"));
            }

            cell.insert(new Element("br"));
        });
        var resign = new Element("button").updateText("Resign");
        resign.onclick = function() {
            appendCommand("resign\n");
        };
        cell1.insert(new Element("hr"));
        cell1.insert(resign);
        parent.insert(div);
    }
    if (record.type == "pick-color") {
        var div = new Element("div", { "id": "leech-" + index + "-0",
                                       "style": "padding-left: 2em" });
        var available = { "green": true,
                          "blue": true,
                          "black": true,
                          "brown": true,
                          "yellow": true,
                          "red": true,
                          "gray": true
                        };

        $H(state.factions).each(function(elem) {
            var used_faction = elem.value;
            if (available[used_faction.color]) {
                available[used_faction.color] = false;
            }
            if (state.round == 0 &&
                used_faction.secondary_color &&
                available[used_faction.secondary_color]) {
                available[used_faction.secondary_color] = false;
            }
        });

        $H(available).each(function(elem) {
            var color = elem.key;
            var ok = elem.value;
            if (!ok) {
                var notAvailable = new Element("button").updateText(
                    "Already taken");
                notAvailable.style.backgroundColor = bgcolors[color];
                notAvailable.style.color = contrastColor[color];
                notAvailable.disabled = true;
                div.insert(notAvailable);
            } else {
                var button = new Element("button").updateText(color);
                button.onclick = function() {
                    appendCommand("pick-color " + color + "\n");
                };
                button.style.backgroundColor = bgcolors[color];
                button.style.color = contrastColor[color];
                div.insert(button);
            }
            div.insert(new Element("br"));
        });
        parent.insert(div);
    }
    if (record.type == "unlock-terrain") {
        var div = new Element("div", { "id": "leech-" + index + "-0",
                                       "style": "padding-left: 2em" });
        var locked = faction.locked_terrain;

        $H(locked).each(function(elem) {
            var color = elem.key;
            var ok = elem.value;
            if (ok) {
                var button = new Element("button").updateText(color);
                button.onclick = function() {
                    appendCommand("unlock-terrain " + color + "\n");
                };
                button.style.backgroundColor = bgcolors[color];
                button.style.color = contrastColor[color];
                div.insert(button);
                div.insert(new Element("br"));
            }
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

            if (hex.color != faction.color &&
                hex.color != faction.secondary_color) {
                return;
            }

            if (hex.building) {
                return;
            }

            var button = new Element("button").updateText(elem.key);
            button.onclick = function() {
                $("leech-" + index).style.display = "none";
                appendCommand("build #{key}\n".interpolate(elem));
            };
            addMapClickHandler("Build", elem.key, {
                "D": {
                    "fun": function (loc) {
                        appendAndPreview("build " + loc);
                    },
                    "label": "free"
                }
            });
            div.insert(button);
        });

        if (faction.FREE_D > 0) {
            div.insert(makeDeclineButton("FREE_D", faction.FREE_D));
        }

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

            if (hex.color != faction.color) {
                return;
            }

            if (hex.building != record.from_building) {
                return;
            }

            var button = new Element("button").updateText(elem.key);
            button.onclick = function() {
                $("leech-" + index).style.display = "none";
                appendCommand("Upgrade " + elem.key + " to #{to_building}\n".interpolate(record));
            };
            div.insert(button);                                               

            addMapClickHandler("Upgrade", elem.key, {
                "TP": {
                    "fun": function (loc) {
                        appendCommand("Upgrade " + loc + " to #{to_building}\n".interpolate(record));
                    },
                    "label": "free"
                }
            });
        });

        if (faction.FREE_TP > 0) {
            div.insert(makeDeclineButton("FREE_TP", faction.FREE_TP));
        }
        parent.insert(div);
    }
    if (record.type == "bridge") {
        var div = new Element("div", { "id": "leech-" + index,
                                       "style": "padding-left: 2em" });
        var already_added = {};

        $H(state.map).sortBy(naturalSortKey).each(function(elem) {
            var coord = elem.key;
            var hex = elem.value;

            if (!faction.BRIDGE_COUNT) {
                return;
            }

            if (hex.row == null) {
                return;
            }

            if (hex.color != faction.color) {
                return;
            }

            if (!hex.building) {
                return;
            }

            var menu = {};
            $H(hex.bridgable).each(function(to) {
                var ok = true;
                state.bridges.each(function(bridge) {
                    if ((bridge.to == coord || bridge.from == coord) &&
                        (bridge.to == to.key || bridge.from == to.key)) {
                        ok = false;
                    }
                });
                if (ok) {
                    menu["To " + to.key] = {
                        "fun": function (loc) {
                            appendCommand("Bridge " + elem.key + ":" + to.key);
                        },
                        "label": ""
                    };
                }
            });
            if ($H(menu).size() > 0) {
                addMapClickHandler("Bridge", elem.key, menu);
            }
        });

        if (faction.BRIDGE > 0) {
            div.insert(makeDeclineButton("BRIDGE", faction.BRIDGE));
        }

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
    } else if (amount < 0) {
        appendCommand("-#{amount}#{resource}".interpolate(record));
    } else {
        appendCommand("+#{amount_pretty}#{resource}".interpolate(record));
    }
}

function moveEntryInputChanged() {
    if (!$("move_entry_input")) {
        return;
    }

    $("move_entry_input").oninput = null;
    $("move_entry_action").updateText("Preview");
    $("move_entry_action").onclick = preview;
    $("move_entry_action").enable();
    $("move_entry_explanation").clearContent();
} 

function dataEntrySetStatus(disabled) {
    $("data_entry").descendants().each(function (elem) {
        elem.disabled = disabled;
    });
}

function moveEntryEnabled() {
    return !$("move_entry_input").disabled && $("move_entry").visible();
}

function moveEntryAfterPreview() {
    if ($("move_entry_action")) {
        $("move_entry_explanation").clearContent();
        $("move_entry_action").updateText("Preview");
        $("move_entry_action").onclick = preview;

        if ($("move_entry_input").value != "") {
            if ($("error").innerHTML != "") {
                $("move_entry_explanation").insert(
                    new Element("div").updateText(
                        "Can't save yet - input had errors"));
            } else if (!allowSaving) {
                $("move_entry_explanation").insert(
                    new Element("div").updateText(
                        "Can't save yet - it's still your turn to move. (Also see the 'wait' command)."));
            } else {
                $("move_entry_action").updateText("Save");
                $("move_entry_action").onclick = save;
            }
        }
        (state.preview_warnings || []).each(function (warning) {
            $("move_entry_explanation").insert(
                new Element("div").updateText("Warning: " + warning));
        });
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
    if (!picker || !faction || faction.placeholder) {
        return;
    }

    if (!faction.allowed_sub_actions) {
        faction.allowed_sub_actions = {};
    }

    var undo = addUndoToMovePicker(picker, faction);
    if (!faction.can_leech && !faction.BRIDGE) {
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
}

function makeSelectWithOptions(options) {
    var select = new Element("select");
    options.each(function (elem) {
        select.insert(new Element("option").updateText(elem));
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
        row.clearContent();
    }

    return row;
}

function addUndoToMovePicker(picker, faction) {
    var validate = function() {
        if (state.action_required[0] &&
            state.action_required[0].faction != faction.name &&
            !faction.waiting &&
            // Hack. For some reason a lot of people react to digging
            // with too many cubes by pressing "wait" rather than
            // fixing the error. This puts the game into a stuck
            // state: after the "wait" is acted on, the player can't
            // undo past the wait. Admin intervention is required.
            !faction.SPADE &&
            state.action_required.some(function (record) {
                return record.faction == faction.name;
            })) {
            wait.enable();
        } else {
            wait.disable();
        }

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
    var execute_wait = function() {
        appendAndPreview("wait");
    }
        
    var row = insertOrClearPickerRow(picker, "move_picker_undo");
    var undo = new Element("button").updateText("Undo");
    undo.onclick = execute_undo;
    undo.disable();

    var done = new Element("button").updateText("Done");
    done.onclick = execute_done;
    done.disable();

    var wait = new Element("button").updateText("Wait");
    wait.onclick = execute_wait;
    wait.disable();

    row.insert(undo);
    row.insertTextSpan(" /  ");
    row.insert(done);
    row.insertTextSpan(" /  ");
    row.insert(wait);

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
    var button = new Element("button").updateText("Pass");
    button.onclick = execute;
    button.disable();
    row.insert(button);

    var bonus_tiles = makeSelectWithOptions(["-"]);
    bonus_tiles.onchange = validate;
    if (state.round < 6) {
        row.insertTextSpan(" and take tile ");
        $H(state.pool).sortBy(naturalSortKey).each(function (tile) {
            if (tile.key.startsWith("BON") && tile.value > 0) {
                addAnnotatedOptionToSelect(bonus_tiles, tile.key,
                                        state.bonus_tiles[tile.key])
            }
        });
        row.insert(bonus_tiles);
    }

    validate();
    
    if (faction.allowed_actions) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function markActionAsPossible(canvas, name, key) {
    renderAction(canvas, name, key, colors.activeUI);
}

function addActionToMovePicker(picker, faction) {
    var validate = function() {
        if (action.value == "-") {
            button.disable();
        } else {
            button.enable();
        }
    };
    var action_pw_cost = function(action) {
        var pw_discount = 0;
        if (faction.discount && faction.discount[action]) {
            pw_discount = faction.discount[action].PW || 0;
        }
        var pw_cost = state.actions[action].cost.PW - pw_discount;
        return pw_cost;
    }
    var action_not_blocked = function(key, fkey) {
        var blocked = (state.map[fkey] && state.map[fkey].blocked);
        var allowed = faction.allow_reuse && faction.allow_reuse[key];

        return !blocked || allowed;
    };
    var execute = function() {
        var command = "action " + action.value;
        var pw_cost = action_pw_cost(action.value);
        if (burn.checked && pw_cost > faction.P3) {
            command = "burn " + (pw_cost - faction.P3) + ". " + command;
        }
        appendAndPreview(command);
    };

    var row = insertOrClearPickerRow(picker, "move_picker_action");
    var button = new Element("button").updateText("Action");
    button.onclick = execute;
    button.disable();
    row.insert(button);

    var possible_actions = [];
    var action = makeSelectWithOptions([]);
    var action_count = 0;

    var generate = function () {
        action.clearContent();
        action.insert(new Element("option").updateText("-"));
        action.onchange = validate;
        var pw = faction.P3;
        var max_pw = pw + faction.P2 / 2;
        if (burn.checked) { pw += max_pw; }
        $H(state.pool).sortBy(naturalSortKey).each(function (elem) {
            var key = elem.key;
            if (!key.startsWith("ACT")) { return; }
            var action_canvas = $("action/" + key);
            action_canvas.onclick = function() { };
            var pw_cost = action_pw_cost(key);
            if (action_not_blocked(key, key) &&
                max_pw >= pw_cost) {
                if (pw >= pw_cost) {
                    var burn = "";
                    if (pw_cost > faction.P3) {
                        burn = " (burn " + (pw_cost - faction.P3) + ")";
                    }
                    var discount = (faction.discount ? faction.discount[key] : {})
                    possible_actions.push({
                        "key": key,
                        "name": elem.key,
                        "cost": effectString([state.actions[key].cost],
                                             // HACK: treat discounts as
                                             // a gain here
                                             [discount]) + burn,
                        "canvas": action_canvas,
                    });
                }
                action_count++;
            }
        });
        $H(faction).sortBy(naturalSortKey).each(function (elem) {
            var key = elem.key;
            var fkey = elem.key;
            if (!key.startsWith("ACT")) {
                fkey += "/" + faction.name;
            }
            if (!state.actions[key] ||
                !elem.value) {
                return;
            }

            var action_canvas = $("action/" + fkey);
            action_canvas.onclick = function() {};

            var cost = state.actions[key].cost;
            var can_afford = cost ? canAfford(faction, [cost]) : true;

            if (action_not_blocked(key, fkey) && can_afford) {
                possible_actions.push({
                    "key": key,
                    "name": elem.key,
                    "cost": cost ? effectString([cost], []) : "free",
                    "canvas": action_canvas,
                });
                action_count++;
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
               updateText(", burn power if needed"));
    row.insert(burn);
    
    if (faction.allowed_actions && action_count > 0) {
        possible_actions.each(function (possible_action) {
            var key = possible_action.key;
            var name = possible_action.name;
            var canvas = possible_action.canvas;

            addAnnotatedOptionToSelect(action, key, state.actions[key]);
            
            var menu_items = {
                "Take": {
                    "fun": function() {
                        if (moveEntryEnabled()) {
                            action.value = key;
                            execute();
                        }
                    },
                    "label": possible_action.cost
                }
            };
            var menuHandler = 
                menuClickHandler("Action",
                                 "",
                                 menu_items);
            canvas.onclick = function (event) {
                menuHandler(name, event);
            };
            markActionAsPossible(canvas, name, key);
        });
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function addAnnotatedOptionToSelect(select, name, record) {
    var label = "";

    if (name.match(/BON/)) {
        label = tileLabel(record);
    } else {
        label = actionLabel(record)
    }

    if (label) {
        label = ": " + label;
    }
    var bonus_coins = ""
    if (state.bonus_coins[name] && state.bonus_coins[name].C) {
        bonus_coins = (" [#{C}c]".interpolate(state.bonus_coins[name]));
    }
    label = name + bonus_coins + label;

    select.insert(new Element("option", {"value": name}).updateText(label));
}

function tileLabel(record) {
    var label = [];

    var income = record.income;
    var pass_vp = record.pass_vp;
    var action = record.action;
    var special = record.special;
    var gain = record.gain;

    if (pass_vp) {
        var vp_strs = [];
        $H(pass_vp).each(function (elem) {
            elem.value = passVpString(elem.value);
            vp_strs.push("#{key}#{value}".interpolate(elem));
        });
        if (vp_strs) {
            label.push("pass-vp " + vp_strs.join(" "))
        }
    }
    if (income) {
        var income_strs = [];
        $H(income).each(function (elem) {
            income_strs.push("+#{value}#{key}".interpolate(elem));
        });
        if (income_strs) {
            label.push("income " + income_strs.join(" "))
        }
    }
    if (action) {
        label.push("action " + actionLabel(record.action));
    }
    if (special) {
        var special_strs = [];
        $H(special).each(function (elem, index) {
            special_strs.push("#{value} #{key}".interpolate(elem));
        });
        if (special_strs) {
            label.push("special " + special_strs.join(" "));
        }
    }
    if (gain) {
        var gain_strs = [];
        $H(gain).each(function (elem) {
            if (elem.value == 1) {
                gain_strs.push(elem.key);
            } else {
                gain_strs.push("#{value}#{key}".interpolate(elem));
            }
        });
        if (gain_strs) {
            label.push(" \u2192 " + gain_strs.join(", "));
        }
    }    

    return label.join(", ");
}

function actionLabel(record) {
    var label = "";

    var cost = record.cost;
    var gain = record.gain;

    if (cost) {
        var cost_strs = [];
        $H(cost).each(function (elem) {
            cost_strs.push("#{value}#{key}".interpolate(elem));
        });
        label += cost_strs.join(", ");
    }

    if (gain) {
        var gain_strs = [];
        $H(gain).each(function (elem) {
            if (elem.value == 1) {
                gain_strs.push(elem.key);
            } else {
                gain_strs.push("#{value}#{key}".interpolate(elem));
            }
        });
        if (gain_strs) {
            label += " \u2192 " + gain_strs.join(", ");
        }
    }    

    return label;
}

function prettyResource(type, amount) {
    if (type == "PW_TOKEN") {
        if (amount == 1) {
            return "pw token"
        } else {
            return "pw tokens"
        }
    } else {
        return type.toLowerCase()
    }
}

function effectString(costs, gains) {
    var non_zero = [];
    ["C", "W", "P", "PW", "PW_TOKEN", "VP"].each(function(type) {
        var delta = 0;
        gains.each(function (gain) { if (gain[type]) { delta += gain[type] } });
        costs.each(function (cost) { if (cost[type]) { delta -= cost[type] } });
        if (!delta) { return; }
        non_zero.push(delta + prettyResource(type, delta));
    });

    return non_zero.join(", ");
}

function canAfford(faction, costs, count) {
    var can_afford = true;
    var non_zero = [];
    if (count == null) {
        count = 1;
    }
    faction.PW_TOKEN = faction.P1 + faction.P2 + faction.P3;
    faction.PW = faction.P2 / 2 + faction.P3;

    ["C", "W", "P", "PW", "PW_TOKEN", "VP"].each(function(type) {
        var total_cost = 0;
        costs.each(function (cost) {
            if (cost[type]) {
                total_cost += cost[type] * count;
            }
        });
        if (faction[type] < total_cost) {
            return can_afford = false;
        }
    });

    return can_afford;
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
        appendAndPreview(command);
    };

    var dwelling_costs = faction.buildings["D"].advance_cost;

    var row = insertOrClearPickerRow(picker, "move_picker_build");
    var button = new Element("button").updateText("Build");
    button.onclick = execute;

    var location = makeSelectWithOptions([]);
    location.onchange = validate;
    var possible_builds = [];
    var gains = computeBuildingEffect(faction, 'D');

    if (faction.allowed_sub_actions.build) {
        var can_afford_build = canAfford(faction, [dwelling_costs]);
        var cost_str = effectString([dwelling_costs], gains);
        if (can_afford_build) {
            $H(faction.allowed_build_locations).each(function (elem) {
                var loc = elem.key;
                possible_builds.push([loc, cost_str]);
            });
        }
    } else if (faction.allowed_actions &&
               faction.reachable_build_locations) {
        location.insert(new Element("option").updateText("-"));
        var resources = ["C", "W", "P"];
        faction.reachable_build_locations.each(function (elem) {
            var loc = elem.hex;
            var loc_cost = elem.extra_cost;
            var can_afford_build = canAfford(faction,
                                             [dwelling_costs, loc_cost]);
            var cost_str = effectString([dwelling_costs, loc_cost],
                                        gains.concat(elem.extra_gain));
            if (can_afford_build) {
                possible_builds.push([loc, cost_str]);
            }
        });
    }

    row.insert(button);
    row.insertTextSpan(" in ");
    row.insert(location);

    validate();
    
    if (faction.buildings.D.level < faction.buildings.D.max_level &&
        !faction.SPADE &&
        (faction.allowed_actions ||
         faction.allowed_sub_actions.build) &&
        possible_builds.size() > 0) {
        possible_builds.each(function (elem) {
            var loc = elem[0];
            var cost = elem[1];
            location.insert(new Element("option").updateText(loc));
            addMapClickHandler("Build", loc, {
                "D": {
                    "fun": function (loc) {
                        appendAndPreview("build " + loc);
                    },
                    "label": cost
                }
            });
        });
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function computeBuildingEffect(faction, type) {
    var res = [];

    $H(faction).each(function (elem) {
        var name = elem.key;
        if (!elem.value) {
            return;
        }
        if (name.match(/^FAV/)) {
            var effect = state.favors[name].vp;
            if (effect && effect[type]) {
                res.push({ "VP": effect[type] })
            }
        }
    });

    var building_record = faction.buildings[type];
    if (building_record.advance_gain &&
        building_record.level < building_record.max_level) {
        res.push(building_record.advance_gain[building_record.level]);
    }

    if (state.round > 0) {
        var score = state.score_tiles[state.round - 1];
        if (score.vp[type]) {
            res.push({ "VP": score.vp[type] })            
        }
    }

    return res;
}

function addUpgradeToMovePicker(picker, faction) {
    var validate = function() {
        if (upgrade.value == "-") {
            button.disable();
        } else {
            button.enable();
        }
    };
    var execute = function() {
        var command = "upgrade " + upgrade.value;
        appendAndPreview(command);
    };

    var row = insertOrClearPickerRow(picker, "move_picker_upgrade");
    var button = new Element("button").updateText("Upgrade");
    button.onclick = execute;
    button.disable();
    row.insert(button);

    var upgrade = makeSelectWithOptions(["-"]);
    var upgrade_count = 0;
    var upgrade_locations = {};
    upgrade.onchange = validate;

    var upgrade_types = $H({ 'TP': 'D',
                             'TE': 'TP',
                             'SA': 'TE',
                             'SH': 'TP' });
    var upgrade_gains = $H({ 'TP': computeBuildingEffect(faction, 'TP'),
                             'TE': computeBuildingEffect(faction, 'TE'),
                             'SA': computeBuildingEffect(faction, 'SA'),
                             'SH': computeBuildingEffect(faction, 'SH') });

    $H(state.map).sortBy(naturalSortKey).each(function (elem) {
        var hex = elem.value;
        var id = elem.key;
        if (hex.row == null || 
            hex.color != faction.color) {
            return
        }
        upgrade_types.each(function (type_elem) {
            var wanted_new = type_elem.key;
            var wanted_old = type_elem.value;
            if (hex.building != wanted_old) {
                return;
            }
            if (faction.buildings[wanted_new].level >=
                faction.buildings[wanted_new].max_level) {
                return;
            }
            var cost = faction.buildings[wanted_new].advance_cost;
            var lonely_cost = {}
            if (wanted_new == "TP" && !hex.has_neighbors) {
                lonely_cost = { "C": cost.C };
            }
            var can_afford = canAfford(faction, [cost, lonely_cost]);
            var cost_str = effectString([cost, lonely_cost],
                                        upgrade_gains.get(wanted_new));
            if (can_afford) {
                upgrade.insert(new Element("option").updateText(
                    id + " to " + wanted_new));
                if (!upgrade_locations[id]) {
                    upgrade_locations[id] = [];
                }
                upgrade_locations[id].push([wanted_new, cost_str]);
                upgrade_count++;
            }
        });
    });
    row.insert(upgrade);
    
    if (faction.allowed_actions && upgrade_count > 0) {
        $H(upgrade_locations).each(function (elem) {
            var loc = elem.key;
            var types = elem.value;
            var execute = function(loc, type) {
                appendAndPreview("upgrade " + loc + " to " + type);
            }
            var funs = {};
            types.each(function (record) {
                var type = record[0];
                var cost = record[1];
                funs[type] = {
                    "fun": execute,
                    "label": cost,
                }
            });
            addMapClickHandler("Upgrade", loc, funs);
        });
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

    var button = new Element("button").updateText("Burn");
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
    row.insertTextSpan(" power");

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
    var convert_possible = false;

    var generate = function () {
        amount.clearContent();
        if (type.value == '-') {
            amount.insert(new Element("option").updateText("-"));
        } else {
            var types = type.value.split(/,/);
            var from_type = types[0];
            var to_type = types[1];
            var rate = faction.exchange_rates[from_type][to_type];
            for (var i = 1; rate * i <= faction[from_type] && i < 10; i++) {
                amount.insert(new Element("option").updateText(i));
            }
        }
    };

    var row = insertOrClearPickerRow(picker, "move_picker_convert");

    var button = new Element("button").updateText("Convert");
    button.onclick = execute;
    button.disable();

    var type = makeSelectWithOptions([]);
    type.onchange = function() {
        generate();
        validate();
    };

    var rates = $H(faction.exchange_rates);
    rates.sortBy(naturalSortKey).reverse().each(function (elem) {
        var from = elem.key;
        var from_type = from == "P" ? "Priest" : from;
        var to = $H(elem.value);
        var need_label = false;
        to.sortBy(naturalSortKey).reverse().each(function (to_elem) {
            var to_type = to_elem.key;
            var rate = to_elem.value;

            if (faction[from] >= rate) {
                var label = from_type + " to " + to_type;
                if (rate > 1) {
                    label = rate + " " +label;
                }
                type.insert({"top": new Element("option",
                                                { "value": from + "," + to_type }).updateText("\u00a0\u00a0" + label)});
                convert_possible = true;
                need_label = true;
            }
        });
        if (need_label) {
            type.insert({"top": new Element("option", {"value": "-"}).updateText(from_type)});
        }
    });

    type.insert({"top": new Element("option", {"selected": true, "value": "-"}).updateText("-")});

    var amount = makeSelectWithOptions(["-"]);

    row.insert(button);
    row.insert(type);
    row.insert(amount);
    row.insertTextSpan(" times");
 
    if (convert_possible &&
        (faction.allowed_actions > 0 ||
         faction.allowed_sub_actions.burn > 0)) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function addDigToMovePicker(picker, faction) {
    if (!faction.dig) {
        return;
    }

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

    var button = new Element("button").updateText("Dig");
    button.onclick = execute;
    button.disable();

    var amount = makeSelectWithOptions(["-"]);
    var amount_count = 0;
    amount.onchange = validate;

    var cost = faction.dig.cost[faction.dig.level];
    if (!cost) {
        return;
    }
    for (var i = 1; i <= 7; ++i) {
        var can_afford = canAfford(faction, [cost], i);        
        if (can_afford) {
            amount_count++;
            amount.insert(new Element("option").updateText(i));
        }
    }

    row.insert(button);
    row.insert(amount);
    row.insertTextSpan(" times");
 
    if ((faction.allowed_actions || faction.allowed_sub_actions.dig) &&
        amount_count > 0) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function addSendToMovePicker(picker, faction) {
    var validate = function() {
        var cult = cult_selection.value.toUpperCase();
        if (cult == "-") {
            button.disable()
            return;
        }
        button.enable()
    };
    var execute = function() {
        var command = "send p to " + cult_selection.value;
        if (amount.value != 'max') {
            command += " for " + amount.value;
        }
        appendAndPreview(command);
    };

    var row = insertOrClearPickerRow(picker, "move_picker_send");

    var button = new Element("button").updateText("Send");
    button.onclick = execute;
    button.disable();
    var cult_selection = makeSelectWithOptions(["-", "Fire", "Water", "Earth", "Air"]);
    cult_selection.onchange = validate;
    var amount = makeSelectWithOptions(["max", "3", "2", "1"]);
    amount.onchange = validate;

    row.insert(button);
    row.insertTextSpan("priest to ");
    row.insert(cult_selection);
    row.insertTextSpan(" for ");
    row.insert(amount);

    if (faction.P > 0 && faction.allowed_actions) {
        cults.each(function (cult) {
            addCultClickHandler("Send Priest", cult, {
                "Max steps": {
                    "fun": function (cult) {
                        appendAndPreview("send p to " + cult);
                    },
                    "label": ""
                },
                "1 step": {
                    "fun": function (cult) {
                        appendAndPreview("send p to " + cult + " for 1");
                    },
                    "label": ""
                }
            });
        });
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

    var button = new Element("button").updateText("Advance");
    button.onclick = execute;
    button.disable();

    var track = makeSelectWithOptions(["-"]);
    var track_count = 0;
    track.onchange = validate;

    ["dig", "ship"].each(function (type) {
        if (!faction[type] ||
            faction[type].level >= faction[type].max_level) {
            return;
        }

        var can_afford = canAfford(faction,
                                   [faction[type].advance_cost]);
        if (can_afford) {
            track.insert(new Element("option").updateText(type));
            track_count++;
        }
    });

    row.insert(button);
    row.insertTextSpan(" on ");
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
    var button = new Element("button").updateText("Connect");
    button.onclick = execute;

    var location = makeSelectWithOptions(["-"].concat(faction.possible_towns));
    location.onchange = validate;
    var location_count = 0;

    faction.possible_towns.each(function (loc) {
        addMapClickHandler("Connect", loc, { "Form town": {
            "fun": function (loc) {
                appendAndPreview("connect " + loc);
            },
            "label": ""
        }});
    });

    row.insert(button);
    row.insertTextSpan(" over ");
    row.insert(location);
    row.insertTextSpan(" to form town ");

    validate();
    
    if (faction.possible_towns.size() > 0) {
        row.show();
    } else {
        row.hide();
    }

    return row;
}

function clearNextGameNotification() {
    $("next_game").hide();    
}

function showNextGameNotification() {
    if (!currentFaction ||
        currentPlayerShouldMove()) {
        $("next_game").hide();
    } else {
        $("next_game").show();
    }
}

function updateInfoTab() {
    var tab = $('info_entry');
    var metadata = state.metadata;

    var table = new Element("table", { "class": "settings-table" });
    var addRow = function(label, data) {
        var row = new Element("tr");
        row.insert(new Element("td").updateText(label));
        if (data instanceof String) {
            row.insert(new Element("td").updateText(data));
        } else {
            row.insert(new Element("td").update(data));
        }
        table.insert(row);
    };

    {
        var url = "https://" + document.location.host + "/game/" + TM.params.game;
        addRow("Public Link",
               new Element("a", { href: url }).updateText(url));
    }

    var tournament = TM.params.game.match(/4pLeague_S(\d+)_D(\d+)L(\d+)_G(\d+)/);
    if (tournament) {
        var s = tournament[1];
        var d = tournament[2];
        var l = tournament[3];
        var url = 'http://tmtour.org/#/seasons/' + s + '/divisions/' + d + '/leagues/' + l;
        addRow("Tournament page",
               new Element("a", { href: url }).updateText("Season " + s + ", D" + d + "L" + l));
    }

    {
        var status = "Running, last update " + seconds_to_pretty_time(state.metadata.time_since_update) + " ago";
        if (metadata.aborted) {
            status = "Aborted";
        } else if (metadata.finished) {
        status = "Finished";
        } else if (metadata.wanted_player_count &&
                   metadata.player_count != metadata.wanted_player_count) {
            status = "Waiting for players";
        }

        if (metadata.exclude_from_stats) {
            status += " (excluded from statistics and rankings)";
        }

        addRow("Status", status);
    }

    {
        var admin = state.metadata.admin_user;
        if (admin) {
            var link = playerLink(admin, admin);
            addRow("Admin", link);
        }
    }

    addRow("Description", state.metadata.description || "[no description]");

    if (state.metadata.chess_clock_hours_initial == null) {
        var hours = state.metadata.deadline_hours || 168;
        var style = "";
        if (hours <= 1*24) {
            style = "color: #f00; font-weight: bold";
        } else if (hours <= 3*24) {
            style = "color: #f00";
        }
        addRow("Move timer", seconds_to_pretty_time((hours) * 3600));
    } else {
        var hours = state.current_chess_clock_hours;
        addRow("Chess clock", seconds_to_pretty_time((hours) * 3600, 'hour')
               + " (" + seconds_to_pretty_time((state.metadata.chess_clock_hours_initial) * 3600) +
               " + " + seconds_to_pretty_time((state.metadata.chess_clock_hours_per_round) * 3600, 'hour') + " per round), grace period " +
              seconds_to_pretty_time((state.metadata.chess_clock_grace_period) * 3600))
    }

    // Time taken by each player
    if (metadata.active_times &&
        metadata.active_times[0] &&
        metadata.active_times[0].game) {
        var list = new Element("table", { "class": "time-taken-table"});
        var grace_period = [0, 8, 12, 24, 72];

        var header = new Element("tr").insert(new Element("td"));
        list.insert(header);
        grace_period.each(function (grace) {
            var label = seconds_to_pretty_time(grace * 3600);
            var style = "";
            if (!grace) { label = "No grace period"; }

            if (grace == state.metadata.chess_clock_grace_period) {
                style = "font-weight: bold";
            } 

            header.insert(new Element("td", {style: style}).updateText(label));
        });

        metadata.active_times.each(function (record) {
            var player = record.player;
            var row = new Element("tr");
            var link = playerLink(player, player);
            row.insert(new Element("td").insert(link));

            grace_period.each(function (grace) {
                var style = "";
                var field = "active_seconds_" + grace + "h";
                if (!grace) { field = "active_seconds" }
                var value_seconds = record[field];
                var value_pretty = "";
                if (value_seconds) {
                    value_pretty = seconds_to_pretty_time(value_seconds, 'hour');
                }
                if (grace == state.metadata.chess_clock_grace_period) {
                    style = "font-weight: bold";
                } 
                row.insert(new Element("td", {style: style}).insert(value_pretty));
            });

            list.insert(row);
        });
        var help = new Element("p").updateText("The time taken by each player is tracked both as a raw value (the clock starts running immediately), as well as with different grace periods (the clock starts running only after the indicated period of inactivity).");
        var div = new Element("div").insert(help).insert(list);
        addRow("Time taken", div);
    }

    if (metadata.map_variant) {
        var label = mapNamesById[metadata.map_variant] || "Alternate";
        addRow("Map",
               new Element("a", {href:"/map/" + metadata.map_variant}).updateText(label));
    }

    // Options
    if (metadata.game_options) {
        var list = new Element("ul");
        metadata.game_options.sort().each(function (elem) {
            list.insert(new Element("li").updateText(elem));        
        });
        addRow("Options", list);
    }

    tab.update(table);
}

function draw(n) {
    $("error").clearContent();
    var errors = false;
    state.error.each(function(row) {
        errors = true;
        $("error").insert(new Element("div").updateText(row));
    });

    if ($("main-data")) {
        $("main-data").style.display = "block";
    }

    drawMap();
    drawCults();
    drawScoringTiles();
    drawFactions();
    // Draw this after factions, so that we can manipulate the DOM of
    // the action markers.
    drawActionRequired();
    drawTurnOrder();
    // Draw the full ledger right from the start when in history view.
    recent_moves = drawLedger(state.history_view || errors);
    drawRecentMoves(recent_moves);

    if (state.history_view > 0) {
        $("root").style.backgroundColor = "#ffeedd";
    }

    showNextGameNotification();
}

function failed() {
    $("action_required").clearContent();
    $("error").clearContent();
    if (state.error) {
        state.error.each(function(row) {
            $("error").insert(new Element("div").updateText(row));
        });
    } else {
        $("error").insertTextSpan("Couldn't load game");
    }
}

function spin() {
    $("action_required").clearContent();
    $("action_required").insert(new Element("img",
                                            { src: "/stc/spinner.gif" }));
    $("action_required").insertTextSpan('loading ...');
}

function useColorBlindMode() {
    var ls = window.localStorage;
    if (!ls) {
        return false;
    }

    return ls['color-blind-mode'] == "true";
}

function toggleColorBlindMode() {
    var ls = window.localStorage;
    if (!ls) {
        return false;
    }

    var cb_mode = ls['color-blind-mode'];
    ls['color-blind-mode'] = (cb_mode != "true");

    document.location.reload();
}

function init(root) {
    root.innerHTML += ' \
    <table style="border-style: none" id="main-data"> \
      <tr> \
        <td> \
          <div id="map-container"> \
            <canvas id="map" width="1600" height="1000"> \
              Browser not supported. \
            </canvas> \
          </div> \
        <td> \
          <div id="cult-container"> \
            <canvas id="cults" width="500" height="1000"> \
              Browser not supported. \
            </canvas> \
          </div> \
      <tr> \
        <td> \
          <td> <a style="color: black" href="#" onclick="toggleColorBlindMode()">Toggle color blind mode</a> \
      <tr> \
        <td colspan=2> \
          <div style="display: inline-block; vertical-align: top"> \
            <div id="shared-actions"></div> \
            <div id="turn-order"></div> \
          </div> \
          <div id="scoring"></div> \
    </table> \
    <div id="menu" class="menu" style="display: none"></div> \
    <div id="preview_status"></div> \
    <pre id="preview_commands"></pre> \
    <div id="error"></div> \
    <div id="action_required"></div> \
    <div id="next_game"></div> \
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

    loadGame(document.location.host, document.location.pathname);
    fetchGames($("user-info"), "user", "running", showActiveGames);

    setInterval(function() {
        fetchGames($("user-info"), "user", "running", showActiveGames);
    }, 5*60*1000);
}

