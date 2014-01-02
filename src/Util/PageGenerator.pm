package Util::PageGenerator;
use Exporter::Easy (EXPORT => [ 'generate_page' ]);

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

    my @script_records = ();

    for my $script (@{$data->{scripts}}) {
        if ($script =~ /^http/) {
            push @script_records, { url => $script, csum => '' };
        } else {
            my $script_content = read_file "$root/$script";
            my $csum = sha1_hex $script_content;
            push @script_records, { url => $script,
                                    csum => $csum };
        }
    }

    $data->{scripts} = [ @script_records ];

    my $layout = "$dir/layout/$data->{layout}.html";
    my $template = Text::Template->new(TYPE => 'FILE',
                                       SOURCE => $layout);
    die "Could not render page '$name', layout '$layout'\n" if !$template;

    return $template->fill_in(HASH => $data);    
}

sub read_then_close {
    my ($fh) = @_;
    my $data = join '', <$fh>;
    close $fh;
    $data;
};

1;
