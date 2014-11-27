{
    layout => 'sidebar',
    scripts => [ "/stc/common.js" ],
    title => 'Blog',
    content => read_then_close(*DATA)
}

__DATA__
<p>
  This is an index of blog posts on this site, or occasionally on 
  Terra Mystica more generally.
</p>

<div id="blog" class="changelog"></div>

<script language="javascript">
  fetchChangelog(function(news) {
      showChangelog(news, $("blog"), "Blog Posts", {"blog": true })
  });
</script>
