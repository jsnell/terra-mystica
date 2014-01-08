package Util::PageGenerator;
use Exporter::Easy (EXPORT => [ 'generate_page' ]);

use strict;

use Digest::SHA1 qw(sha1_hex);
use File::Slurp qw(read_file);
use Text::Template;

sub generate_page {
    my ($root, $name) = @_;
    my $dir = "$root/pages/";

    $name =~ s/[^a-z]//g;
    my $content = "$dir/content/$name.pl";
    die "No content file '$content'\n" if !-f $content;
    my $data = do $content;

    my $layout = "$dir/layout/$data->{layout}.html";
    my $template = Text::Template->new(TYPE => 'FILE',
                                       SOURCE => $layout);
    die "Could not render page '$name', layout '$layout'\n" if !$template;

    $data->{root} = $root;

    return $template->fill_in(HASH => $data);    
}

sub static_resource_link {
    my ($root, $path) = @_;

    if ($path =~ /^http/) {
        return $path;
    } else {
        my $path_content = read_file "$root/$path";
        my $csum = sha1_hex $path_content;
        return "$path?tag=$csum";
    }
}

sub read_then_close {
    my ($fh) = @_;
    my $data = join '', <$fh>;
    close $fh;
    $data;
}

1;
