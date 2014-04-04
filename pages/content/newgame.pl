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
  <table>
    <tr style="vertical-align: top">
      <td style="width: 12ex">Game id<td><input name="gameid" id="gameid" oninput="javascript:newGameValidate()">
        <p>The id of the game should be unique, and only contain
the letters A-Z and a-z and the digits 0-9.
    </tr>
    <tr style="vertical-align: top">
      <td>Options
      <td>
        <input name="game-options" type="checkbox" id="option-mini-expansion-1" value="mini-expansion-1"></input><label for="option-mini-expansion-1">Mini Expansion #1 (town tiles)</label><br>
        <input name="game-options" type="checkbox" id="option-shipping-bonus" value="shipping-bonus"></input><label for="option-shipping-bonus">Shipping bonus tile (Spielbox 6/2013)</label><br>
        <input name="game-options" type="checkbox" id="option-email-notify" value="email-notify" onchange="javascript:newGameValidate()" checked></input><label id="option-email-notify-label" for="option-email-notify">Automatic email notifications</label><br>
        <p>
The options are described in more detail in the
<a href="/usage.html#options">manual.</a>
    </tr>
    <tr style="vertical-align: top" >
      <td>Game type
      <td>
        <select name="game-type" id="game-type" onchange="javascript:newGameValidate()">
<option>-</option>
<option value="private">Private</option>
<option value="public">Public</option>
        </select>
        <p>
Private games are created with a predetermined set of players.
Public games can be joined by any player on the site.
    </tr>
    <tr style="vertical-align: top" id="players-row" style="display: none">
      <td>Players<td><textarea name="players" id="players" style="width: 40ex; height: 6em;" oninput="javascript:newGameValidate()" placeholder="usernames or email addresses"></textarea>
        <p>
You can specify the players either using a
username or an email address (must be registered
on the site). One player per row, at least two
players required. <b>You can't change who is playing
after creating the game.</b>
        <p>
Please do not add players to games if they aren't
expecting it.
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
        <p>
The game will start automatically once this many
players have joined.
    </tr>
    <tr style="vertical-align: top" id="description-row" style="display: none">
      <td>Description<td><textarea name="description" id="description" style="width: 40ex; height: 6em;" style="display: none"></textarea>
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
  <script language="javascript">newGameValidate();</script>
</form>
