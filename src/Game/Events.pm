package Game::Events;
use Moose;
use Method::Signatures::Simple;

use resources;

has 'game' => (is => 'rw', required => 1);

has 'faction' => (is => 'rw',
                  default => sub { {} });

has 'global' => (is => 'rw',
                  default => sub { {} });
                  
method faction_event($faction, $event, $count) {
    if (!defined $count) {
        die "$event\n";
    }

    for my $name ('all', $faction->{name}) {
        for my $round ('all', $self->game()->{round}) {
            $self->faction()->{$name}{$event}{round}{$round} += $count;
        }
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
        global => $self->global()
    }
}

1;
