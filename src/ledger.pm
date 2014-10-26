package terra_mystica::Ledger;
use Moose;
use Method::Signatures::Simple;

use resources;

has 'game' => (is => 'rw', required => 1);

# The data we're collecting
has 'rows' => (is => 'rw',
               traits => ['Array'],
               default => sub { [] },
               handles => {
                   size => 'count',
                   add_row => 'push',
               });

# Information related to adding turn / round comments at the right place
has ['last_printed_round',
     'last_printed_turn']
     => (is => 'rw', isa => 'Int', default => 0);
has 'trailing_comment' => (is => 'rw', isa => 'Bool');

# Data collected about the current row so far
has 'collecting_row' => (is => 'rw', default => 0);
has 'current_faction' => (is => 'rw');
has 'commands' => (is => '',
                   traits => ['Array'],
                   default => sub { [] },
                   handles => {
                       commands => 'elements',
                       add_command => 'push',
                       clear_commands => 'clear',
                       join_commands => 'join',
                   });
has 'force_finish_row' => (is => 'rw', default => 0);
has 'start_resources' => (is => 'rw');
has 'warnings' => (is => '',
                   traits => ['Array'],
                   default => sub { [] },
                   handles => {
                       warn => 'push',
                       clear_warnings => 'clear',
                       warnings => 'elements',
                       first_warning => [ get => 0 ],
                   });
has 'leech' => (is => 'rw', default => sub { {} });

my @data_fields = qw(VP C W P P1 P2 P3 PW FIRE WATER EARTH AIR CULT);

after add_row => sub {
    my ($self, $row) = @_;
    $self->trailing_comment(0);
};

method start_new_row($faction) {
    return if $self->collecting_row();

    $self->collecting_row(1);
    $self->current_faction($faction);
    $self->force_finish_row(0);
    $self->clear_commands();
    $self->clear_warnings();
    $self->leech({});
    $self->start_resources(
        { map { ( $_, $faction->{$_}) } @data_fields });
}

before add_command => sub {
    my ($self, $command) = @_;
    die if !$self->collecting_row();
};

method report_leech($faction_name, $amount) {    
    $self->leech()->{$faction_name} += $amount;
}

method finish_row {
    return if !$self->collecting_row();

    my $faction = $self->current_faction();

    # Compute the delta
    my %end_resources = map { $_, $faction->{$_} } @data_fields;
    my %pretty_delta = ();

    if ($faction->{dummy}) {
        %pretty_delta = map { ($_, 0) } @data_fields;
    } else {
        %pretty_delta = terra_mystica::pretty_resource_delta($self->start_resources(),
                                                             \%end_resources);
    }
    
    my $info = { faction => $faction->{name},
                 leech => $self->leech(),
                 warning => $self->first_warning() // "",
                 commands => $self->join_commands(". "),
                 map { $_, $pretty_delta{$_} } @data_fields};

    my $row_summary = "$faction->{name}: $info->{commands}";

    my $game = $self->game();

    if (!$game->{finished}) {
        for my $f ($game->{acting}->factions_in_order()) {
            push @{$f->{recent_moves}}, $row_summary;
        }
    }

    $self->add_row($info);
    $self->collecting_row(0);
}

method add_comment($comment) {
    $self->add_row({ comment => $comment });
    $self->trailing_comment(1);
}

method add_row_for_effect($faction, $command, $fun) {
    my %old_data = map { $_, $faction->{$_} } @data_fields;
    $fun->($faction);
    my %new_data = map { $_, $faction->{$_} } @data_fields;
    my %pretty_delta = terra_mystica::pretty_resource_delta(\%old_data, \%new_data);

    $self->add_row({
        faction => $faction->{name},
        commands => $command,
        map { $_, $pretty_delta{$_} } @data_fields
    });

}

method turn($round, $turn) {
    if ($round == $self->last_printed_round() and
        $turn == $self->last_printed_turn()) {
        return;
    }

    $self->last_printed_turn($turn);
    $self->last_printed_round($round);

    return if $self->{trailing_comment};

    $self->add_comment("Round $round, turn $turn");
}

method flush {
    $self->finish_row();
    $self->rows();
}


1;
