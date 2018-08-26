use strict;

package Server::Map;

use Digest::SHA qw(sha1_hex);
use Moose;
use Method::Signatures::Simple;

extends 'Server::Server';

use Analyze::EloVpPredictor;
use DB::Connection qw(get_db_connection);
use DB::Game;
use Game::Constants;
use map;
use Server::Security;
use Server::Session;
use tracker;
use Util::SiteConfig;

has 'mode' => (is => 'ro', required => 1);

method handle($q, $id) {
    $self->no_cache();

    my $dbh = get_db_connection;

    my $base_map = $q->param('base_map');

    my $res = {
        error => [],
        bridges => [],
    };

    if ($self->mode() eq 'view') {
        view($dbh, $id, $res, $q->param('map-only') // 1);
    } else {
        my $username = username_from_session_token(
            $dbh,
            $q->cookie('session-token') // '');

        if (!defined $username) {
            $self->output_json({
                error => [ "Not logged in\n" ]
                               });
            return;
        }

        if ($self->mode() eq 'preview') {
            preview($dbh, $q->param('map-data'), $res);
        } elsif ($self->mode() eq 'save') {
            save($dbh, $q->param('map-data'), $res, $username);
        }
    }

    $self->output_json($res);
};

func convert_to_lodev($base_map) {
    $base_map =~ s/\s+/ /g;
    $base_map =~ s/\s*E\s*/;\n/g; 
    $base_map =~ s/black/K/g;
    $base_map =~ s/blue/B/g;
    $base_map =~ s/brown/U/g;
    $base_map =~ s/green/G/g;
    $base_map =~ s/gray/S/g;
    $base_map =~ s/red/R/g;
    $base_map =~ s/yellow/Y/g;
    $base_map =~ s/x/I/g;
    $base_map =~ s/ /,/g;
    $base_map;
}

func convert_from_lodev($base_map) {
    if ($base_map =~ /^N/) {
        $base_map = ";$base_map";
    }    
    $base_map =~ s/N,?//g;

    $base_map =~ s/K/black/g;
    $base_map =~ s/B/blue/g;
    $base_map =~ s/U/brown/g;
    $base_map =~ s/G/green/g;
    $base_map =~ s/S/gray/g;
    $base_map =~ s/R/red/g;
    $base_map =~ s/Y/yellow/g;
    $base_map =~ s/I/x/g;
    $base_map =~ s/;\s*/ E /g;
    $base_map =~ s/^ +//g;
    $base_map =~ s/ +$//g;
    $base_map =~ s/,/ /g;
    $base_map =~ s/ +/ /g;
    $base_map;
}

func preview($dbh, $mapdata, $res) {
    my $map_str = convert_from_lodev($mapdata);
    my $base_map = [ split /\s+/, $map_str ];
    my $map = terra_mystica::setup_map $base_map;

    my $id = sha1_hex $map_str;

    $res->{'map'} = $map;
    $res->{'mapdata'} = $mapdata;
    $res->{'mapid'} = $id;
    $res->{'saved'} = map_exists($dbh, $id);
}

func map_exists($dbh, $id) {
    my ($count) = $dbh->selectrow_array("select count(*) from map_variant where id=?",
                                        {},
                                        $id);
    $count ? 1 : 0;
}

func save($dbh, $mapdata, $res, $username) {
    if ($username ne $config{site_admin_username} and $username ne 'nan') {
        die "Sorry, creating new maps isn't allowed\n"
    }

    my $map_str = convert_from_lodev($mapdata);
    my $id = sha1_hex $map_str;

    if (!map_exists($dbh, $id)) {
        $dbh->do("insert into map_variant (id, terrain) values (?, ?)",
                 {},
                 $id, $map_str);
    }

    $res->{'mapid'} = sha1_hex $map_str;
}

func view($dbh, $id, $res, $map_only) {
    my ($map_str, $vp_variant) = $dbh->selectrow_array("select terrain, vp_variant from map_variant where id=?", {}, $id);
    my $base_map = [ split /\s+/, $map_str ];
    my $map = terra_mystica::setup_map $base_map;

    $res->{'map'} = $map;
    $res->{'mapdata'} = convert_to_lodev($map_str);
    $res->{'mapid'} = $id;

    if ($id ne '224736500d20520f195970eb0fd4c41df040c08c' and
        $id ne '54919e13090127079e7cc3540ad0065311f2ecd7' and 
        $id ne '2afadc63f4d81e850b7c16fb21a1dcd29658c392') {
        $map_only = 1;
    }
    
    if (!$map_only) {
        my $game_ids = $dbh->selectall_arrayref("select id, round, finished, array (select faction || ' ' || vp from game_role where game=game.id order by vp desc) as factions from game where base_map=? and player_count > 2 and not aborted order by finished, round, id",
                                                { Slice => {} },
                                                $id);

        $res->{'games'} = $game_ids;

        $res->{'vpstats'} = faction_vp_error_by_map $dbh, $id;
    }

    if ($vp_variant) {
        $res->{vp_setup} = $Game::Constants::vp_setups{$vp_variant};
    }
}

1;
