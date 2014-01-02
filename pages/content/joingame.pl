{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/joingame.js"],
    title => 'Open Games',
    content => read_then_close(*DATA)
}

__DATA__
<div id="error"></div>
<table class="open-games" id="games">
</table>

<script language="javascript">
  fetchOpenGames();
</script>
