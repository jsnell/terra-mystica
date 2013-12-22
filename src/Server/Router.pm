package Server::Router;

use Server::Alias;
use Server::AppendGame;
use Server::Chat;
use Server::EditGame;
use Server::EditGame;
use Server::JoinGame;
use Server::ListGames;
use Server::Login;
use Server::Logout;
use Server::Plan;
use Server::Register;
use Server::SaveGame;
use Server::Settings;
use Server::Template;
use Server::ViewGame;

use CGI::PSGI;
use JSON;

my %paths = (
   '/alias/' => sub {
       Server::Alias->new({ mode => 'request' })
    },
   '/append-game/' => sub {
       Server::AppendGame->new()
    },
   '/chat/' => sub {
       Server::Chat->new()
    },
   '/edit-game/' => sub {
       Server::EditGame->new()
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
   '/register/' => sub {
       Server::Register->new({ mode => 'request' })
    },
   '/save-game/' => sub {
       Server::SaveGame->new()
    },
   '/settings/' => sub {
       Server::Settings->new()
    },
   '/validate-alias/' => sub {
       Server::Alias->new({ mode => 'validate' })
    },
   '/validate-registration/' => sub {
       Server::Register->new({ mode => 'validate' })
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
        print STDERR "ERROR: $@\n", '-'x60, "\n";
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
