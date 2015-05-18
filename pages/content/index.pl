{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/index.js" ],
    title => 'Online Terra Mystica',
    content => read_then_close(*DATA)
}

__DATA__

<div class="motd" style="display: block">
    Season 7 of the Terra Mystica tournament will start on June 1st.
    Sign ups are now open on the <a href="http://tmtour.org">tournament website</a>.

    <p>
Please note that as of this season, controlling multiple players is
explicitly forbidden by the tournament rules.
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
