use strict;

package Util::SiteConfig;
use Exporter::Easy (EXPORT => [ '%config' ]);

use JSON;

use vars qw(%config);

{
  die "TM_CONFIG not provided" if !$ENV{'TM_CONFIG'};
  my $config_fn = $ENV{'TM_CONFIG'};
  open(my $config_fh, "<:encoding(UTF-8)", $config_fn)
    or die("Can't open configuration file \"$config_fn\": $!\n");
  local $/;
  %config = %{JSON->new->decode(<$config_fh>)};
  close $config_fh;
}

1;
