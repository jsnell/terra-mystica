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
        <input name="game-options" type="checkbox" id="option-email-notify" value="email-notify" onchange="javascript:newGameValidate()" checked></input><label id="option-email-notify-label" for="option-email-notify">Automatic email notifications</label><br>
        <input name="game-options" type="checkbox" id="option-maintain-player-order" value="maintain-player-order" onchange="javascript:newGameValidate()"></input><label id="option-maintain-player-order-label" for="option-maintain-player-order">Don't randomize player order (private games only)</label><br>
      <td>
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
      <td>        
        <p>
          Players will be dropped from the game after this period of
          inactivity. The game admin can reinstate a dropped player, but
          will lose admin privileges for the game if dropped out themselves.
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
  <script language="javascript">newGameValidate();</script>
</form>
