package Util::PageGenerator;
use Exporter::Easy (EXPORT => [ 'generate_page' ]);

use strict;

use Digest::SHA qw(sha1_hex);
use File::Slurp qw(read_file);
use JSON;
use Text::Template;

my %page_data_cache = ();

sub get_page_data {
    my ($dir, $name) = @_;
    my $content_file = "$dir/content/$name.pl";
    die "No content file '$content_file'\n" if !-f $content_file;
    my $mtime = (stat($content_file))[9];

    if (!defined $page_data_cache{$content_file}{mtime} or
        $mtime > $page_data_cache{$content_file}{mtime}) {
        $page_data_cache{$content_file}{mtime} = $mtime;
        $page_data_cache{$content_file}{content} = do $content_file;
    }        

    $page_data_cache{$content_file}{content};
}

sub generate_page {
    my ($root, $name, $params) = @_;
    my $dir = "$root/pages/";

    $name =~ s/[^a-z]//g;
    my $data = get_page_data $dir, $name;

    if ($data->{title} and $data->{title} !~ /Terra Mystica/) {
        $data->{head_title} = "$data->{title} - Terra Mystica";
    } else {
        $data->{head_title} = $data->{title};
    }
    
    my $layout = "$dir/layout/$data->{layout}.html";
    my $template = Text::Template->new(TYPE => 'FILE',
                                       SOURCE => $layout);
    die "Could not render page '$name', layout '$layout'\n" if !$template;

    if ($data->{require_access}) {
        if ($data->{require_access} ne $params->{access}) {
            print STDERR "Access denied to $name: ", encode_json $params, "\n";
            die "Access restricted\n";
        }
    }

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
