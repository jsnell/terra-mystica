package Server::Router;

use Server::AppendGame;
use Server::Chat;
use Server::JoinGame;
use Server::ListGames;
use Server::Login;
use Server::Logout;
use Server::Plan;
use Server::Template;
use Server::ViewGame;

use CGI::PSGI;
use JSON;

my %paths = (
   '/append-game/' => sub {
       Server::AppendGame->new()
    },
   '/chat/' => sub {
       Server::Chat->new()
    },
   '/join-game/' => sub {
       Server::JoinGame->new()
    },
   '/list-games/' => sub {
       Server::ListGames->new()
    },
   '/login/' => sub {
       Server::Login->new()
    },
   '/logout/' => sub {
       Server::Logout->new()
    },
   '/plan/' => sub {
       Server::Plan->new()
    },
   '/view-game/' => sub {
       Server::ViewGame->new()
    },
);

my @prefix_paths = (
   [qr{^/template/} => sub { Server::Template->new() }],
);

sub route {
    my $env = shift;
    my $q = CGI::PSGI->new($env);

    my $path_info = $q->path_info();
    my $ret;

    eval {
        my ($handler) = $paths{$path_info} // (map { $_->[1] } grep { $path_info =~ $_->[0] } @prefix_paths);
        if ($handler) {
            my $app = $handler->();
            $app->handle($q);
            $ret = $app->output_psgi();
        } else {
            die "Unknown module '$path_info'";
        }
    }; if ($@) {
        $ret = [500,
                ["Content-Type", "application/json"],
                [encode_json { error => $@ }]];
    }

    $ret;
};

sub psgi_router {
    route(@_);
}

1;
