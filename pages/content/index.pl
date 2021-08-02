{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/index.js" ],
    title => 'Online Terra Mystica',
    content => read_then_close(*DATA)
}

__DATA__

<div class="motd" style="display: none">
    Season 44 of the Terra Mystica tournament is underway!
    The tournament can be discussed in the <a href="https://boardgamegeek.com/thread/2545591/seasons-40-49-terra-mystica-tournament">BGG thread</a>. 
</div>

<h4>Your Active / Recently Finished Games</h4>
<table id="yourgames-active" class="gamelist"></table>

<h4>Games you Administrate</h4>
<table id="yourgames-admin" class="gamelist"></table>

<div id="news" class="changelog"></div>

<script language="javascript">
fetchGames("yourgames-active", "user", "running", listGames);
fetchGames("yourgames-admin", "admin", "running", listGames);

setInterval(function() {
fetchGames("yourgames-active", "user", "running", listGames);
}, 5*60*1000);

fetchChangelog(function(news) {
    showChangelog(news, $("news"), "News", { "change": true, "blog": true },
                  10 * 86400)
});
</script>

</div>
