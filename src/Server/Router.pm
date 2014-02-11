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
use Server::PasswordReset;
use Server::Plan;
use Server::Register;
use Server::NewGame;
use Server::Results;
use Server::SaveGame;
use Server::Settings;
use Server::Template;
use Server::ViewGame;

use CGI::PSGI;
use JSON;

my %paths = (
    '/alias/request/' => sub {
        Server::Alias->new({ mode => 'request' })
    },
    '/alias/validate/' => sub {
        Server::Alias->new({ mode => 'validate' })
    },
    '/append-game/' => sub {
        Server::AppendGame->new()
    },
    '/chat/' => sub {
        Server::Chat->new()
    },
    '/edit-game/' => sub {
        Server::EditGame->new({ mode => 'content' })
    },
    '/set-game-status/' => sub {
        Server::EditGame->new({ mode => 'status' })
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
    '/new-game/' => sub {
        Server::NewGame->new()
    },
    '/plan/' => sub {
        Server::Plan->new()
    },
    '/register/request/' => sub {
        Server::Register->new({ mode => 'request' })
    },
    '/register/validate/' => sub {
        Server::Register->new({ mode => 'validate' })
    },
    '/reset/request/' => sub {
        Server::PasswordReset->new({ mode => 'request' })
    },
    '/reset/validate/' => sub {
        Server::PasswordReset->new({ mode => 'validate' })
    },
    '/results/' => sub {
        Server::Results->new()
    },
    '/template/' => sub {
        Server::Template->new()
    },
    '/save-game/' => sub {
        Server::SaveGame->new()
    },
    '/settings/' => sub {
        Server::Settings->new()
    },
    '/view-game/' => sub {
        Server::ViewGame->new()
    },
);

sub route {
    my $env = shift;
    my $q = CGI::PSGI->new($env);

    my $path_info = $q->path_info();
    my $ret;

    eval {
        my $handler = undef;
        my $suffix = '';
        my @components = split m{/}, $path_info;
        for my $i (reverse 0..$#components) {
            my $prefix = join '/', @components[0..$i];
            $prefix .= '/';
            $handler = $paths{$prefix};
            if ($handler) {
                $suffix = substr $path_info, length $prefix;
                last;
            }
        }
        if ($handler) {
            my $app = $handler->();
            $app->handle($q, $suffix);
            $ret = $app->output_psgi();
        } else {
            die "Unknown module '$path_info'";
        }
    }; if ($@) {
        print STDERR "ERROR: $@\n", '-'x60, "\n";
        $ret = [500,
                ["Content-Type", "application/json"],
                [encode_json { error => [ $@ ] }]];
    }

    $ret;
};

sub psgi_router {
    route(@_);
}

1;
