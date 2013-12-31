{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/index.js" ],
    title => 'Online Terra Mystica',
    content => join '', <DATA>
}

__DATA__
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
