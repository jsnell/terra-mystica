#!/usr/bin/perl -w

use File::Basename qw(dirname);
use File::Copy;
use File::Path qw(make_path);
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

    make_path dirname $to;

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
    for my $f (qw(alias.pl
                  append.pl
                  chat.pl
                  app.fcgi
                  app.psgi
                  edit.pl
                  gamelist.pl
                  joingame.pl
                  login.pl
                  logout.pl
                  newgame.pl
                  plan.pl
                  register.pl
                  reset.pl
                  results.pl
                  settings.pl
                  startup-modperl2.pl
                  template.pl 
                  validate.pl
                  validate-alias.pl
                  validate-reset.pl
                  save.pl)) {
        copy_with_mode 0555, "src/$f", "$target/cgi-bin/$f";
    }

    for my $f (qw(acting.pm
                  buildings.pm
                  commands.pm
                  create_game.pm
                  cryptutil.pm
                  cults.pm
                  db.pm
                  editlink.pm
                  exec_timer.pm
                  factions.pm
                  game.pm
                  income.pm
                  indexgame.pm
                  ledger.pm
                  map.pm
                  natural_cmp.pm
                  notify.pm
                  results.pm
                  resources.pm
                  rlimit.pm
                  save.pm
                  scoring.pm
                  secret.pm
                  Server/Server.pm
                  Server/ViewGame.pm 
                  session.pm
                  tiles.pm
                  towns.pm
                  tracker.pm
                  user_validate.pm)) {
        copy_with_mode 0444, "src/$f", "$target/cgi-bin/$f";
    }
}

sub deploy_stc {
    mkdir "$target/stc";
    for my $f (qw(alias.js
                  common.js
                  debug.js
                  edit.js
                  faction.js
                  game.js
                  index.js
                  joingame.js
                  newgame.js
                  ratings.js
                  register.js
                  reset.js
                  prototype-1.7.1.js
                  org.css
                  settings.js
                  spinner.gif
                  stats.js
                  style.css)) {
        copy_with_mode 0444, "stc/$f", "$target/stc/$f";
    }
    copy_with_mode 0444, "stc/favicon.ico", "$target/favicon.ico";
    copy_with_mode 0444, "stc/favicon-inactive.ico", "$target/favicon-inactive.ico";
}

sub deploy_html {
    for my $f (qw(alias.html
                  changes.html
                  edit.html
                  faction.html
                  game.html
                  index.html
                  joingame.html
                  login.html
                  newgame.html
                  player.html
                  ratings.html
                  register.html
                  reset.html
                  robots.txt
                  settings.html
                  stats.html
                  )) {
        my $to = "$target/$f";

        mangle_with_mode 0444, "$f", "$to", sub {
            local $_ = shift;
            s{=(['"])(/stc/.*)\1}{=$1$2?tag=$tag$1}g;
            $_;
        }
    }
}

sub deploy_data {
    for my $f (qw(changes.json)) {
        my $to = "$target/data/$f";
        copy_with_mode 0444, $f, $to;
    }
}

deploy_docs;
deploy_stc;
deploy_cgi;
deploy_html;
deploy_data;

system qq{(echo -n "$target: "; git rev-parse HEAD) >> deploy.log};
