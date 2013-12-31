{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/index.js" ],
    title => 'Player Information',
    content => join '', <DATA>
}

__DATA__
<h4>Active / Recently Finished Games</h4>
<table id="games-active" class="gamelist"></table>

<h4>Finished Games</h4>
<table id="games-finished" class="gamelist"></table>

<script language="javascript">
  var path = document.location.pathname.split("/");
  var user = path[2];

  $("heading").innerHTML += " - " + user;
  
  fetchGames("games-active", "other-user", "running", listGames, user);
  fetchGames("games-finished", "other-user", "finished", listGames, user);
</script>
