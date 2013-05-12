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

my %untracked = map {
    (/ (.*)/g, 1)
} grep {
    /^\?/
} qx(git status --porcelain);

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

    if ($untracked{$from}) {
        die "untracked file '$from'\n"
    }

    copy $from, "$to.tmp" or die "Error copying $from to $to: $!";
    chmod $mode, "$to.tmp";
    rename "$to.tmp", $to;
}

sub mangle_with_mode {
    my ($mode, $from, $to, $mangle) = @_;
    my $data = $mangle->(scalar slurp "$from");

    if ($devel) {
        if (!-l $to) {
            symlink "$ENV{PWD}/$from", $to;
        }
        return;
    }

    my ($fh, $filename) = tempfile("tmpfileXXXXXXX",
                                   DIR=>"$target");
    print $fh $data;
    close $fh;
    chmod $mode, $filename;
    rename $filename, $to;
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
                  login.pl
                  logout.pl
                  newgame.pl
                  register.pl
                  reset.pl
                  results.pl
                  validate.pl
                  validate-reset.pl
                  status.pl
                  save.pl)) {
        copy_with_mode 0555, "src/$f", "$target/cgi-bin/$f";
    }

    mangle_with_mode 0555, "src/res.pl", "$target/cgi-bin/res.pl", sub {
        local $_ = shift;
        s/%%GIT_VERSION%%/$tag/;
        $_;
    };

    for my $f (qw(buildings.pm
                  commands.pm
                  create_game.pm
                  cults.pm
                  editlink.pm
                  exec_timer.pm
                  factions.pm
                  income.pm
                  indexgame.pm
                  lockfile.pm
                  map.pm
                  natural_cmp.pm
                  results.pm
                  resources.pm
                  rlimit.pm
                  scoring.pm
                  session.pm
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
                  register.js
                  reset.js
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
                  index.html
                  login.html
                  newgame.html
                  register.html
                  reset.html
                  stats.html)) {
        my $to = "$target/$f";

        mangle_with_mode 0444, "$f", "$to", sub {
            local $_ = shift;
            s{=(['"])(/stc/.*)\1}{=$1$2?tag=$tag$1}g;
            $_;
        }
    }
}

deploy_docs;
deploy_stc;
deploy_cgi;
deploy_html;

