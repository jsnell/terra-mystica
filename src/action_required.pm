package terra_mystica::ActionRequired;
use Mouse;

use resources;

has 'actions' => (is => 'rw',
                default => sub { [] });

sub unrequire_action {
    my ($self, $faction, $type);

    my @new_actions = grep {
        $_->{faction} eq $faction->{name}
    } @{$self->actions()};
    $self->actions(@new_actions);
}



1;
