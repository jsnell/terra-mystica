#!/usr/bin/perl -w

use File::Copy;
use File::Slurp qw(slurp);
use File::Temp qw(tempfile);
use Fatal qw(open chmod rename symlink);

my $target = shift;

die "Usage: $0 target\n" if !$target or @ARGV;

die "Directory $target does not exist" if !-d $target;

my $tag = qx(git rev-parse HEAD);
my $devel = ($target eq 'www-devel');

if (!$devel) {
    system "git", "diff", "--exit-code";

    if ($?) {
        die "Uncommitted changes, can't deploy";
    }
}

sub copy_with_mode {
    my ($mode, $from, $to) = @_;
    die if -d $to;

    if ($devel) {
        if (!-l $to) {
            symlink "$ENV{PWD}/$from", $to;
        }
        return 
    }

    copy $from, "$to.tmp" or die "Error copying $from to $to: $!";
    chmod $mode, "$to.tmp";
    rename "$to.tmp", $to;
}

sub deploy_docs {
    return if $devel;
    system "emacs --batch --file=usage.org --funcall org-export-as-html-batch";
    rename "usage.html", "$target/usage.html"
}

sub deploy_cgi {
    mkdir "$target/cgi-bin";
    for my $f (qw(append.pl
                  bridge.pl
                  edit.pl
                  gamelist.pl
                  save.pl)) {
        copy_with_mode 0555, "src/$f", "$target/cgi-bin/$f";
    }

    for my $f (qw(buildings.pm
                  commands.pm
                  cults.pm
                  exec_timer.pm
                  factions.pm
                  income.pm
                  lockfile.pm
                  map.pm
                  resources.pm
                  scoring.pm
                  tiles.pm
                  towns.pm
                  tracker.pm)) {
        copy_with_mode 0444, "src/$f", "$target/cgi-bin/$f";
    }
}

sub deploy_stc {
    mkdir "$target/stc";
    for my $f (qw(debug.js
                  edit.js
                  faction.js
                  game.js
                  prototype-1.7.1.js
                  org.css
                  spinner.gif
                  style.css)) {
        copy_with_mode 0444, "stc/$f", "$target/stc/$f";
    }
    copy_with_mode 0444, "stc/favicon.ico", "$target/favicon.ico";
}

sub deploy_html {
    for my $f (qw(game.html
                  edit.html
                  faction.html
                  index.html)) {
        my $to = "$target/$f";
        if ($devel) {
            if (!-l $to) {
                symlink "$ENV{PWD}/$f", $to;
            }
            next;
        }

        my $data = slurp "$f";
        $data =~ s{=(['"])(/stc/.*)\1}{=$1$2?tag=$tag$1}g;
        
        my ($fh, $filename) = tempfile("tmpfileXXXXXXX",
                                       DIR=>"$target");
        print $fh $data;
        close $fh;
        chmod 0444, $filename;
        rename $filename, $to;

        copy "$f", $to
    }
}

deploy_docs;
deploy_stc;
deploy_cgi;
deploy_html;

