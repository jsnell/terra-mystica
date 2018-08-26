# -*- mode: html -*-
{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/newgame.js"],
    title => 'New Game',
    content => read_then_close(*DATA)
}

__DATA__
<div id="error"></div>
<form id="newgame" action="/app/new-game/" onsubmit="return false">
  <table class="newgame-settings">
    <tr style="vertical-align: top" id="copy-row">
      <td style="width: 12ex">Template
      <td>
        <input name="copy-gameid" id="copy-gameid"
               oninput="javascript:copyGameValidate()" >
        <input id="copy-submit" type="button" value="Use Template" onclick="javascript:copyGame()"></input>
      <td>
        <p>Use an existing game as a template for this game (fill in the
          the same settings and the same players). You can still edit
          the prefilled form data before creating the game.
    </tr>

    <tr style="vertical-align: top">
      <td style="width: 12ex">Game id<td><input name="gameid" id="gameid" oninput="javascript:newGameValidate()">
      <td>
        <p>The id of the game should be unique, and only contain
the letters A-Z and a-z and the digits 0-9.
    </tr>

    <tr style="vertical-align: top">
      <td>Options
      <td>
        <input name="game-options" type="checkbox" id="option-mini-expansion-1" value="mini-expansion-1"></input><label for="option-mini-expansion-1">Mini Expansion #1 (town tiles)</label><br>
        <input name="game-options" type="checkbox" id="option-shipping-bonus" value="shipping-bonus"></input><label for="option-shipping-bonus">Shipping bonus tile (Spielbox 6/2013)</label><br>
        <input name="game-options" type="checkbox" id="option-temple-scoring-tile" value="temple-scoring-tile"></input><label for="option-temple-scoring-tile">Temple round scoring tile (2015 mini expansion)</label><br>
        <input name="game-options" type="checkbox" id="option-fire-and-ice-final-scoring" value="fire-and-ice-final-scoring"></input><label for="option-fire-and-ice-final-scoring">Extra final scoring tile (Fire &amp; Ice expansion)</label><br>
        <input name="game-options" type="checkbox" id="option-variable-turn-order" value="variable-turn-order"></input><label for="option-variable-turn-order">Turn order determined by passing order (Fire &amp; Ice expansion)</label><br>

        <input type="checkbox" id="option-fire-and-ice-factions" onchange="javascript:newGameValidate()"></input><label for="option-fire-and-ice-factions">Fire &amp; Ice expansion factions</label><br>
        <div style="padding-left: 2em">
          <input name="game-options" type="checkbox" id="option-fire-and-ice-factions/ice" onchange="javascript:newGameValidate()" value="fire-and-ice-factions/ice" checked></input><label for="option-fire-and-ice-factions/ice">Ice factions</label><br>
          <input name="game-options" type="checkbox" id="option-fire-and-ice-factions/variable_v5" onchange="javascript:newGameValidate()" value="fire-and-ice-factions/variable_v5" checked></input><label for="option-fire-and-ice-factions/variable_v5">Variable factions (please note the <a href='https://boardgamegeek.com/thread/1456706/official-change-rules'>official rules change</a>)</label><br>
          <input name="game-options" type="checkbox" id="option-fire-and-ice-factions/volcano" onchange="javascript:newGameValidate()" value="fire-and-ice-factions/volcano" checked></input><label for="option-fire-and-ice-factions/volcano">Volcano factions</label><br>
        </div>

        <br>
        <input name="game-options" type="checkbox" id="option-email-notify" value="email-notify" onchange="javascript:newGameValidate()" checked></input><label id="option-email-notify-label" for="option-email-notify">Automatic email notifications</label><br>
        <input name="game-options" type="checkbox" id="option-maintain-player-order" value="maintain-player-order" onchange="javascript:newGameValidate()"></input><label id="option-maintain-player-order-label" for="option-maintain-player-order">Don't randomize player order (private games only)</label><br>
        
      <td>
        <p>
The options are described in more detail in the
<a href="/usage/#options">manual.</a>
    </tr>

    <tr style="vertical-align: top" >
      <td>Map
      <td>
        <select name="map-variant" id="map-variant" onchange="javascript:newGameValidate()">
<option value="">Original</option>
<option value="91645cdb135773c2a7a50e5ca9cb18af54c664c4">Original [2017 vp]</option>
<option value="95a66999127893f5925a5f591d54f8bcb9a670e6">Fire & Ice, Side 1</option>
<option value="be8f6ebf549404d015547152d5f2a1906ae8dd90">Fire & Ice, Side 2</option>
<option value="fdb13a13cd48b7a3c3525f27e4628ff6905aa5b1">Loon Lakes v1.6</option>
<option value="2afadc63f4d81e850b7c16fb21a1dcd29658c392">Fjords v2.1</option>
        </select>
      <td>
        <p>
          <a href="/map/126fe960806d587c78546b30f1a90853b1ada468" target="_blank">Original</a><br>
          <a href="/map/91645cdb135773c2a7a50e5ca9cb18af54c664c4" target="_blank">Original [2017 vp]</a><br>
          <a href="/map/95a66999127893f5925a5f591d54f8bcb9a670e6" target="_blank">Side 1</a><br>
          <a href="/map/be8f6ebf549404d015547152d5f2a1906ae8dd90" target="_blank">Side 2</a><br>
          <a href="/map/fdb13a13cd48b7a3c3525f27e4628ff6905aa5b1" target="_blank">Loon Lakes v1.6</a><br>
          <a href="/map/2afadc63f4d81e850b7c16fb21a1dcd29658c392" target="_blank">Fjords v2.1</a>
        </p>
    </tr>

    <tr style="vertical-align: top" >
      <td>Game type
      <td>
        <select name="game-type" id="game-type" onchange="javascript:newGameValidate()">
<option>-</option>
<option value="private">Private</option>
<option value="public">Public</option>
        </select>
      <td>
        <p>
Private games are created with a predetermined set of players.
Public games can be joined by any player on the site.
    </tr>

    <tr style="vertical-align: top" id="players-row" style="display: none">
      <td>Players<td><textarea name="players" id="players" style="width: 40ex; height: 6em;" oninput="javascript:newGameValidate()" placeholder="usernames or email addresses"></textarea>
      <td>
        <p>
You can specify the players either using a
username or an email address (must be registered
on the site). One player per row, at least two
players required. You can't change who is playing
after creating the game.
        <p>
<b>Please do not add players to games if they aren't
expecting it.</b>
    </tr>

    <tr style="vertical-align: top" id="player-count-row" style="display: none">
      <td>Player count
      <td><select name="player-count" id="player-count" onchange="javascript:newGameValidate()">
<option selected=true>-</option>
<option>2</option>
<option>3</option>
<option>4</option>
<option>5</option>
</select>
      <td>
        <p>
The game will start automatically once this many
players have joined.
    </tr>

    <tr style="vertical-align: top" id="rating-row" style="display: none">
      <td>Rating restriction
      <td>
        Minimum: <input name=min-rating id=min-rating type=text style="width: 5ex"></input>
        Maximum: <input name=max-rating id=max-rating type=text style="width: 5ex"></input>
      <td>
        <p>
          Only players in this rating range can join the game. Leave
          one or both fields empty if you don't want any restrictions.
          Players who are still unranked are considered to have a
          rating of 0; they can join games with a maximum rating but
          not games with a minimum rating.
    </tr>

    <tr style="vertical-align: top" id="timelimit-method-row">
      <td>Time limit</td>
      <td><select name="timelimit-method" id="timelimit-method" onchange="javascript:newGameValidate()">
          <option value="">-</option>
          <option value="deadline">Per-move timer</option>
          <option value="chess-clock">Chess clock</option>
          </select>
      </td>
      <td>
        <p>
          The method used for dropping slow players. Per-move
          timers limit the amount of time that can be used for each
          single move. The chess clock allows each player to spend a
          certain amount of time on all of their moves in the game.
        </p>
      </td>
    </tr>

    <tr style="vertical-align: top" id="deadline-row">
      <td>Move timer
      <td><select name="deadline-hours" id="deadline-hours">
          <option value="12">12 hours</option>
          <option value="24">1 day</option>
          <option value="72">3 days</option>
          <option value="120">5 days</option>
          <option selected=true value="168">1 week</option>
          <option value="336">2 weeks</option>
        </select>
      </td>
      <td>
        <p>
          Players will be dropped from the game after this period of
          inactivity. The game admin can reinstate a dropped player, but
          will lose admin privileges for the game if dropped out themselves.
        </p>
      </td>
    </tr>

    <tr style="vertical-align: top" id="chess-clock-row">
      <td>Chess clock      
      <td><div class="settings-chessclock-label">Initial time:</div>
        <select name="chess-clock-hours-initial" id="chess-clock-hours-initial">
<option value="48">2 days</option>
<option value="120">5 days</option>
<option selected=true value="240">10 days</option>
<option value="360">15 days</option>
<option value="720">30 days</option>
</select><br>
        <div class="settings-chessclock-label">Time per round:</div>
        <select name="chess-clock-hours-per-round" id="chess-clock-hours-per-round">
<option value="0">No time</option>
<option value="24">1 day</option>
<option selected=true value="48">2 days</option>
<option value="120">5 days</option>
</select><br>
        <div class="settings-chessclock-label">Grace period:</div>
      <select name="chess-clock-grace-period" id="chess-clock-grace-period">
<option value="8">8 hours</option>
<option selected=true value="12">12 hours</option>
<option value="24">1 day</option>
</select>
      <td>        
        <p>
          A clock that determines when to drop players from a game for
          taking too much time. The initial time determines the time
          each player starts with on their clock. The time per round
          is the amount of time added on the clock at start of rounds
          1-6. The grace period is the point after the previous move
          at which the clock starts ticking.
        <p>
          Players who at any point in the game exceed their time
          allotment will be dropped from the game, and can't be brought
          back even by the game admin.
    </tr>

    <tr style="vertical-align: top" id="description-row" style="display: none">
      <td>Description<td><textarea name="description" id="description" style="width: 40ex; height: 6em;" style="display: none"></textarea>
      <td>
        <p>
Any special information related to this game, that
will be shown in the list of open games. Use this
to for example find players of a certain
experience level or living in a certain timezone.
    </tr>

    <tr><td><td>
        <input id="submit" type="button" value="New Game" onclick="javascript:newGame()"></input>
        <p id="new-game-disabled">
Please correct the items marked in red before creating the game.
  </table>
  <input type="hidden" id="csrf-token" name="csrf-token"></input>
  <script language="javascript">newGameValidate(); copyGameValidate();</script>
</form>
