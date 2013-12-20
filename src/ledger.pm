package terra_mystica::Ledger;
use Mouse;

use resources;

# The data we're collecting
has 'rows' => (is => 'rw',
               default => sub { [] });

# Information related to adding turn / round comments at the right place
has ['last_printed_round',
     'last_printed_turn']
     => (is => 'rw', isa => 'Int', default => 0);
has 'trailing_comment' => (is => 'rw', isa => 'Bool');

# Data collected about the current row so far
has 'collecting_row' => (is => 'rw', default => 0);
has 'current_faction' => (is => 'rw');
has 'commands' => (is => 'rw');
has 'force_finish_row' => (is => 'rw', default => 0);
has 'start_resources' => (is => 'rw');
has 'warnings' => (is => 'rw', default => sub { [] });
has 'leech' => (is => 'rw', default => sub { {} });

my @data_fields = qw(VP C W P P1 P2 P3 PW FIRE WATER EARTH AIR CULT);

sub size {
    my ($ledger) = @_;
    return scalar @{$ledger->rows()};
}

sub add_row {
    my ($ledger, $row) = @_;

    push @{$ledger->rows()}, $row;
    $ledger->trailing_comment(0);
}

sub start_new_row {
    my ($ledger, $faction) = @_;
    return if $ledger->collecting_row();

    $ledger->collecting_row(1);
    $ledger->current_faction($faction);
    $ledger->force_finish_row(0);
    $ledger->commands([]);
    $ledger->warnings([]);
    $ledger->leech({});
    $ledger->start_resources(
        { map { ( $_, $faction->{$_}) } @data_fields });
}

sub add_command {
    my ($ledger, $command) = @_;
    return if !$ledger->collecting_row();

    push @{$ledger->commands()}, $command;
}

sub warn {
    my ($ledger, $warning) = @_;

    push @{$ledger->warnings()}, $warning;
}

sub report_leech {
    my ($ledger, $faction_name, $amount) = @_;
    
    $ledger->leech()->{$faction_name} += $amount;
}

sub finish_row {
    my ($ledger) = @_;
    my $faction = $ledger->current_faction();

    # Compute the delta
    my %end_resources = map { $_, $faction->{$_} } @data_fields;
    my %pretty_delta = terra_mystica::pretty_resource_delta($ledger->start_resources(),
                                                            \%end_resources);

    my $info = { faction => $faction->{name},
                 leech => $ledger->leech(),
                 warning => $ledger->warnings()->[0] // "",
                 commands => (join ". ", @{$ledger->commands()}),
                 map { $_, $pretty_delta{$_} } @data_fields};

    my $row_summary = "$faction->{name}: $info->{commands}";

    for my $f (values %terra_mystica::factions) {
        push @{$f->{recent_moves}}, $row_summary;
    }

    $ledger->add_row($info);
    $ledger->collecting_row(0);
}

sub add_comment {
    my ($ledger, $comment) = @_;

    $ledger->add_row({ comment => $comment });
    $ledger->trailing_comment(1);
}

sub turn {
    my ($ledger, $round, $turn) = @_;

    if ($round == $ledger->last_printed_round() and
        $turn == $ledger->last_printed_turn()) {
        return;
    }

    $ledger->last_printed_turn($turn);
    $ledger->last_printed_round($round);

    return if $ledger->{trailing_comment};

    $ledger->add_comment("Round $round, turn $turn");
}

1;
