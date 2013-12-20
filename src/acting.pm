package terra_mystica::Acting;
use Mouse;

has 'active_faction' => (is => 'rw');

sub is_active {
    my ($self, $faction) = @_;

    defined $self->active_faction() and $faction == $self->active_faction();
}

sub active_faction_name {
    my $self = shift;
    my $faction = $self->active_faction();
    $faction and $faction->{name};
}

1;
