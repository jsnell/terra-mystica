package Game::Events;
use Moose;
use Method::Signatures::Simple;

use resources;

has 'game' => (is => 'rw', required => 1);

has 'faction' => (is => 'rw',
                  default => sub { {} });

has 'global' => (is => 'rw',
                  default => sub { {} });

has 'location' => (is => 'rw',
                   default => sub { {} });
                  
method faction_event($faction, $event, $count) {
    if (!defined $count) {
        die "$event\n";
    }

    for my $name ('all', $faction->{name}) {
        my $round = $self->game()->{round};
        my $turn = $self->game()->{turn};
        $self->faction()->{$name}{$event}{round}{$round} += $count;
        $self->faction()->{$name}{$event}{round}{all} += $count;
        $self->faction()->{$name}{$event}{turn}{$round}{$turn} += $count;
    }
}

method location_event($faction, $location) {
    for my $name ($faction->{name}) {
        my $round = $self->game()->{round};
        push @{$self->location()->{$name}{round}{$round}}, $location;
        push @{$self->location()->{$name}{round}{all}}, $location;
    }
}

method global_event($event, $count) {
    for my $round ('all', $self->game()->{round}) {
        $self->global()->{$event}{round}{$round} += $count;
    }
}

method data() {
    return { 
        faction => $self->faction(),
        location => $self->location(),
        global => $self->global()
    }
}

1;
