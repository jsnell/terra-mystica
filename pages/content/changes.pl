{
    layout => 'sidebar',
    scripts => [ "/stc/common.js" ],
    title => 'Changelog',
    content => join '', <DATA>
}

__DATA__
<p>
  This is a list of larger user-visible changes, feature additions, etc.
  For a tedious list including minor bugfixes and cosmetic changes, see the
  <a href="https://github.com/jsnell/terra-mystica/commits/master">version control logs</a>.
</p>

<div id="changes" class="changelog"></div>

<script language="javascript">
  fetchChangelog(function(data) {
      showChangelog(data, $("changes"), "Changes", 365 * 86400)
  });
</script>
