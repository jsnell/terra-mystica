var hex_size = 35;
var hex_width = (Math.cos(Math.PI / 6) * hex_size * 2);
var hex_height = Math.sin(Math.PI / 6) * hex_size + hex_size;

function HexCenter(row, col) {
    var x_offset = row % 2 ? hex_width / 2 : 0;
    var x = 5 + hex_size + col * hex_width + x_offset,
        y = 5 + hex_size + row * hex_height;
    return [x, y];
}

var colors = {
    red: '#e04040',
    green: '#40a040',
    yellow: '#e0e040',
    blue: '#4040e0',
    black: '#000000',
    white: '#ffffff',
    gray: '#808080',
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

function MakeHexPath(ctx, hex) {
    var loc = HexCenter(hex.row, hex.col);
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

function DrawDwelling(ctx, hex) {
    var loc = HexCenter(hex.row, hex.col);

    ctx.save();

    ctx.beginPath();
    ctx.moveTo(loc[0], loc[1] - 10);
    ctx.lineTo(loc[0] + 10, loc[1]);
    ctx.lineTo(loc[0] + 10, loc[1] + 10);
    ctx.lineTo(loc[0] - 10, loc[1] + 10);
    ctx.lineTo(loc[0] - 10, loc[1]);
    ctx.closePath();
    ctx.fillStyle = colors[hex.color];
    ctx.fill();

    ctx.strokeStyle = '#000';
    ctx.lineWidth = 3;
    ctx.stroke();

    ctx.restore();
}

function DrawTradingPost(ctx, hex) {
    var loc = HexCenter(hex.row, hex.col);

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
    ctx.fillStyle = colors[hex.color];
    ctx.fill();

    ctx.strokeStyle = '#000';
    ctx.lineWidth = 3;
    ctx.stroke();

    ctx.restore();
}

function DrawTemple(ctx, hex) {
    var loc = HexCenter(hex.row, hex.col);
    loc[1] -= 5;

    ctx.save();

    ctx.beginPath();
    ctx.arc(loc[0], loc[1], 14, 0, Math.PI*2);
    ctx.fillStyle = colors[hex.color];
    ctx.fill();
    ctx.strokeStyle = "#000";
    ctx.lineWidth = 3;
    ctx.stroke();

    ctx.restore();
}


function DrawStronghold(ctx, hex) {
    var loc = HexCenter(hex.row, hex.col);
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

    ctx.fillStyle = colors[hex.color];
    ctx.fill();
    ctx.strokeStyle = "#000";
    ctx.lineWidth = 3;
    ctx.stroke();

    ctx.restore();
}

function DrawSanctuary(ctx, hex) {
    var loc = HexCenter(hex.row, hex.col);
    var size = 7;
    loc[1] -= 5;

    ctx.save();

    ctx.beginPath();
    ctx.arc(loc[0] - size, loc[1], 12, Math.PI / 2, -Math.PI / 2);
    ctx.arc(loc[0] + size, loc[1], 12, -Math.PI / 2, Math.PI / 2);
    ctx.closePath();
    
    ctx.fillStyle = colors[hex.color];
    ctx.fill();
    ctx.strokeStyle = "#000";
    ctx.lineWidth = 3;
    ctx.stroke();

    ctx.restore();
}

function DrawHex(ctx, elem) {
    if (elem == null) {
        return;
    }

    var hex = elem.value;
    var id = elem.key;

    if (hex.row == null) {
        return;
    }

    MakeHexPath(ctx, hex);

    ctx.save();
    ctx.fillStyle = bgcolors[hex.color];
    ctx.fill();
    ctx.restore();

    ctx.save();
    ctx.strokeStyle = "#000000";
    ctx.lineWidth = 2;
    MakeHexPath(ctx, hex);
    ctx.stroke();
    ctx.restore();

    if (hex.building == 'D') {
        DrawDwelling(ctx, hex);
    } else if (hex.building == 'TP') {
        DrawTradingPost(ctx, hex);
    } else if (hex.building == 'TE') {
        DrawTemple(ctx, hex);
    } else if (hex.building == 'SH') {
        DrawStronghold(ctx, hex);
    } else if (hex.building == 'SA') {
        DrawSanctuary(ctx, hex);
    }

    ctx.save();
    var loc = HexCenter(hex.row, hex.col);
    ctx.strokeStyle = "#000";
    ctx.font = "12px Sans-Serif";
    ctx.strokeText(id, loc[0], loc[1] + hex_size - 12);
    ctx.restore();
}

function DrawMap() {
    var canvas = $("map");
    if (canvas.getContext) {
        var ctx = canvas.getContext("2d");

        $H(state.map).each(function(hex, index) { DrawHex(ctx, hex) });
    }
}

