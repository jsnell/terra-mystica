{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/index.js" ],
    title => 'Online Terra Mystica',
    content => read_then_close(*DATA)
}

__DATA__

<div class="motd" style="display: block">
    Season 20 of the Terra Mystica tournament will start on August 1st.
    Sign ups are now open on the <a href="http://tmtour.org">tournament website</a>, with discussion on the <a href="https://boardgamegeek.com/thread/1813715/tm-tour-season-20-signup-open-games-aug-1">BGG thread</a>.
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

<div class="motd" style="display: none">
If you've played any games on the Loon Lakes 1.3, please consider filling in
the <a href='https://goo.gl/forms/W4cO8qCZKUoIvfdo1'>feedback form</a>
used to guide development. Possible changes to the next version are
currently being <a href="https://boardgamegeek.com/article/23645673#23645673">discussed</a>.
</ul>

</div>
