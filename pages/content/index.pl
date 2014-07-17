{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/index.js" ],
    title => 'Online Terra Mystica',
    content => read_then_close(*DATA)
}

__DATA__

<div class="motd" style="display: block">
    Season 2 of the Terra Mystica tournament will start on August 1st.
    See the <a href="http://boardgamegeek.com/thread/1198844/terra-mystica-tournament-season-2">BGG thread</a> for more information, or sign up on the
    <a href="http://tmtour.org">league website</a>.
</div>

<h4>Your Active / Recently Finished Games</h4>
<table id="yourgames-active" class="gamelist"></table>

<h4>Games you Administrate</h4>
<table id="yourgames-admin" class="gamelist"></table>

<h4>Your Finished Games</h4>
<table id="yourgames-finished" class="gamelist"><tr><td><a href="javascript:fetchGames('yourgames-finished', 'user', 'finished', listGames)">Load</a></table>

<h4>Games you Administrated</h4>
<table id="yourgames-admin-finished" class="gamelist"><tr><td><a href="javascript:fetchGames('yourgames-admin-finished', 'admin', 'finished', listGames)">Load</a></table>

<div id="changes" class="changelog"></div>

<script language="javascript">
fetchGames("yourgames-active", "user", "running", listGames);
fetchGames("yourgames-admin", "admin", "running", listGames);

setInterval(function() {
fetchGames("yourgames-active", "user", "running", listGames);
}, 5*60*1000);

fetchChangelog(function(data) {
showChangelog(data, $("changes"), "Recent Changes", 10 * 86400)
} );
</script>
