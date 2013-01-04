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

function drawText(ctx, text, x, y, font) {
    ctx.save();
    ctx.fillStyle = ctx.strokeStyle;
    ctx.lineWidth = 0.1;
    ctx.font = font;
    ctx.fillText(text, x, y);
    ctx.strokeText(text, x, y);            
    ctx.restore();    
}

function makeHexPath(ctx, hex) {
    var loc = hexCenter(hex.row, hex.col);
    var x = loc[0] - Math.cos(Math.PI / 6) * hex_size;
    var y = loc[1] + Math.sin(Math.PI / 6) * hex_size;
    var angle = 0;
    
    ctx.beginPath();
    ctx.moveTo(x, y);
    for (var i = 0; i < 6; i++) {
        ctx.lineTo(x, y); 
        angle += Math.PI / 3;
        x += Math.sin(angle) * hex_size;
        y += Math.cos(angle) * hex_size;        
    }
    ctx.closePath();
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
    ctx.arc(loc[0], loc[1], 14, 0, Math.PI*2);

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
    ctx.arc(loc[0] - size, loc[1], 12, Math.PI / 2, -Math.PI / 2);
    ctx.arc(loc[0] + size, loc[1], 12, -Math.PI / 2, Math.PI / 2);
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

    makeHexPath(ctx, hex);

    ctx.save();
    ctx.fillStyle = bgcolors[hex.color];
    ctx.fill();
    ctx.restore();

    ctx.save();
    ctx.strokeStyle = "#000000";
    ctx.lineWidth = 2;
    makeHexPath(ctx, hex);
    ctx.stroke();
    ctx.restore();

    if (hex.building == 'D') {
        drawDwelling(ctx, hex);
    } else if (hex.building == 'TP') {
        drawTradingPost(ctx, hex);
    } else if (hex.building == 'TE') {
        drawTemple(ctx, hex);
    } else if (hex.building == 'SH') {
        drawStronghold(ctx, hex);
    } else if (hex.building == 'SA') {
        drawSanctuary(ctx, hex);
    }

    ctx.save();
    var loc = hexCenter(hex.row, hex.col);
    if (hex.color == "black") {
        ctx.strokeStyle = "#c0c0c0";
    } else {
        ctx.strokeStyle = "#000";
    }
    drawText(ctx, id, loc[0] - 9, loc[1] + 25, "12px Verdana");
    ctx.restore();
}

function drawBridge(ctx, from, to, color) {
    var from_loc = hexCenter(state.map[from].row, state.map[from].col);
    var to_loc = hexCenter(state.map[to].row, state.map[to].col);

    ctx.save();

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
        var ctx = canvas.getContext("2d");

        state.bridges.each(function(bridge, index) {
            drawBridge(ctx, bridge.from, bridge.to, bridge.color);
        });

        $H(state.map).each(function(hex, index) { drawHex(ctx, hex) });
    }

    drawCults();
    drawFactions();
    drawLedger();

    state.error.each(function(row) {
        $("error").insert("<div>" + row.escapeHTML() + "</div>");
    });
}

function drawCults() {
    var canvas = $("cults");
    if (canvas.getContext) {
        var ctx = canvas.getContext("2d");

        var cults = ["FIRE", "WATER", "EARTH", "AIR"];
        var bgcolor = ["#f88", "#ccf", "#b84", "#f0f0f0"];
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
            ctx.fillStyle = bgcolor[j];
            ctx.fill();

            drawText(ctx, cult, 5, 15, "15px Verdana");

            ctx.translate(0, 20);

            for (var i = 0; i <= 10; ++i) {
                ctx.save();
                ctx.translate(0, ((10 - i) * 40 + 20));

                drawText(ctx, i, 5, 0, "15px Verdana");

                state.order.each(function(name, index) {
                    var faction = state.factions[name];
                    if (faction[cult] != i) {
                        return;
                    }

                    ctx.translate(9, 0);

                    ctx.save();
                    ctx.beginPath();
                    ctx.arc(0, 10, 6, Math.PI * 2, 0);
                    ctx.fillStyle = colors[faction.color];
                    ctx.fill();
                    ctx.stroke()
                    ctx.restore();
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
    }    
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
        drawText(ctx, name, 1, 45, "12px Georgia");
    }

    ctx.save();
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    var data = {
        "ACT1": function() {
            drawText(ctx, "br", 15, 15, "10px Verdana");
        },
        "ACT2": function() {
            drawText(ctx, "p", 15, 15, "10px Verdana");
        },
        "ACT3": function() {
            drawText(ctx, "2w", 15, 15, "10px Verdana");
        },
        "ACT4": function() {
            drawText(ctx, "7c", 15, 15, "10px Verdana");
        },
        "ACT5": function() {
            drawText(ctx, "sh", 15, 15, "10px Verdana");
        },
        "ACT6": function() {
            drawText(ctx, "2sh", 15, 15, "10px Verdana");
        },
        "ACTA": function() {
            drawText(ctx, "2cult", 15, 15, "10px Verdana");
        },
        "ACTN": function() {
            drawText(ctx, "tf", 15, 15, "10px Verdana");
        },
        "ACTS": function() {
            drawText(ctx, "tp", 15, 15, "10px Verdana");
        },
        "BON1": function() {
            drawText(ctx, "sh", 15, 15, "10px Verdana");
        },
        "BON2": function() {
            drawText(ctx, "cult", 15, 15, "10px Verdana");
        },
        "FAV6": function() {
            drawText(ctx, "cult", 15, 15, "10px Verdana");
        },
    };

    if (data[name]) {
        data[name]();
    }

    ctx.restore();

    ctx.restore();
}

function insertAction(parent, name, key) {
    parent.insert(new Element('canvas', {
        'class': 'action', 'width': 40, 'height': 50}));
    var canvas = parent.childElements().last();
    renderAction(canvas, name, key);
}

function insertIncome(parent, amount) {
    parent.insert("<div class=income>+" + amount + "</div>");
}

function insertScoring(parent, amount) {
    parent.insert("<div class=vp>vp:" + amount + "</div>");
}

function renderBonus(div, name, faction) {
    div.insert(name);
    if (state.map[name].C) {
        div.insert(" [#{C}c]".interpolate(state.map[name]));
    }
    div.insert("<hr>");

    var data = {
        "BON1": function() {
            insertAction(div, name, name + "/" + faction);
            insertIncome(div, "2c");
        }, 
        "BON2": function() {
            insertAction(div, name, name + "/" + faction);
            insertIncome(div, "4c");
        },
        "BON3": function() {
            insertIncome(div, "6c");
        },
        "BON4": function() {
            insertIncome(div, "3pw");
            // XXX
            insertIncome(div, "ship");
        },
        "BON5": function() {
            insertIncome(div, "3pw");
            insertIncome(div, "w");
        },
        "BON6": function() {
            insertScoring(div, "4*SH/SA");
            insertIncome(div, "2w");
        },
        "BON7": function() {
            insertScoring(div, "2*TP");
            insertIncome(div, "w");
        },
        "BON8": function() {
            insertIncome(div, "p");
        },
        "BON9": function() {
            insertScoring(div, "1*D");
            insertIncome(div, "2c");
        },
    };

    if (data[name]) {
        data[name]();
    }
}

function renderFavor(div, name, faction) {
    div.insert(name);
    div.insert("<hr>");
    var favor = div;

    var data = {
        "FAV1": function() {
            favor.insert("3 FIRE");
        }, 
        "FAV2": function() {
            favor.insert("3 WATER");
        }, 
        "FAV3": function() {
            favor.insert("3 EARTH");
        }, 
        "FAV4": function() {
            favor.insert("3 AIR");
        }, 
        "FAV5": function() {
            favor.insert("2 FIRE");
            favor.insert("<br>Town");
        },
        "FAV6": function() {
            favor.insert("2 WATER");
            insertAction(favor, name, name + "/" + faction);
        },
        "FAV7": function() {
            favor.insert("2 EARTH");
            insertIncome(favor, "1pw");
            insertIncome(favor, "1w");
        },
        "FAV8": function() {
            favor.insert("2 AIR");
            insertIncome(favor, "4pw");
        },
        "FAV9": function() {
            favor.insert("1 FIRE");
            insertIncome(favor, "3c");
        },
        "FAV10": function() {
            favor.insert("1 WATER");
            insertScoring(favor, "3*TP");
        },
        "FAV11": function() {
            favor.insert("1 EARTH");
            insertScoring(favor, "2*D");
        },
        "FAV12": function() {
            favor.insert("1 AIR");
            insertScoring(favor, "TPs");
        },
    };

    if (data[name]) {
        data[name]();
    }
}

function renderTreasury(board, treasury, faction) {
    $H(treasury).each(function(elem, index) {
        var name = elem.key;
        var value = elem.value;

        if (value < 1) {
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
            renderFavor(div, name, faction);
            return;
        }
    });
}

function makeBoard(color, name, klass, style) {
    var board = new Element('div', {
        'class': klass,
        'style': style,
    });
    board.insert(new Element('div', {
        'style': 'background-color: ' + colors[color] + '; color: ' +
            (color == 'black' ? '#ccc' : '#000')
    }).update(name));

    return board;
}

function drawFactions() {
    state.order.each(function(name) {
        name = name;
        var faction = state.factions[name];
        var color = faction.color;

        var style ='';
        if (faction.passed) {
            style = 'opacity: 0.5';
        }

        var board = makeBoard(color, name, 'faction-board', style);

        board.insert(new Element('div').update(
            "#{C} c, #{W} w, #{P} p, #{VP} vp".interpolate(faction)));
        board.insert(new Element('div').update(
            "#{P1}/#{P2}/#{P3} power".interpolate(faction)));

        board.insert("<hr>");

        renderTreasury(board, faction, name);
        
        $("factions").insert(board);
    });
    
    var pool = makeBoard("orange", "Pool", 'pool');
    renderTreasury(pool, state.pool, 'pool');
    $("factions").insert(pool);
}

function drawLedger() {
    var ledger = $("ledger");
    state.ledger.each(function(record) {
        if (record.comment) {
            ledger.insert("<tr><td><td colspan=9><b>" + 
                          record.comment.escapeHTML() +
                          "</b></tr>")
        } else {
            record.bg = colors[state.factions[record.faction].color];
            record.fg = (record.bg == '#000000' ? '#ccc' : '#000');
            record.commands = record.commands.escapeHTML();
            ledger.insert("<tr><td style='background-color:#{bg}; color: #{fg}'>#{faction}<td>#{VP}<td>#{C}<td>#{W}<td>#{P}<td>#{PW}<td>#{CULT}<td>#{commands}</tr>".interpolate(
                record));
        }
    });
}

