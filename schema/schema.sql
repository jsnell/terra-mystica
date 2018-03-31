create table player (
  username text primary key,
  password text,
  displayname text,
  email_notify_turn boolean default true,
  email_notify_all_moves boolean default false,
  email_notify_chat boolean default true,
  email_notify_game_status boolean default true
);
create unique index player_username_lowercase_idx on player(lower(username));

create table email (
  address text unique,
  player text references player (username),
  is_primary boolean,
  validated boolean
);
create unique index email_address_lowercase_idx on email(lower(address));

create table to_validate (
  token text primary key,
  payload text,
  created_at timestamp,
  executed boolean default false
);

create table map_variant (
    id text primary key,
    terrain text not null,
    vp_variant text
);

create table game (
    id text primary key,
    write_id text,
    needs_indexing boolean,
    finished boolean default false,
    aborted boolean default false,
    exclude_from_stats boolean default false,
    last_update timestamp,
    player_count integer,
    wanted_player_count integer,
    round integer,
    turn integer,
    commands text,
    -- TODO: remove
    description text,
    game_options text array default '{}',
    base_map text references map_variant (id),
    non_standard boolean default false,
    admin_user text references player (username),
    current_chess_clock_hours integer
);
create index game_finished_idx on game (finished);

create table game_player (
    game text references game (id),
    player text references player (username),
    sort_key text,
    index integer,
    primary key (game, player, index)
);

create table game_active_time (
    game text references game (id),
    player text references player (username),
    active_seconds integer default 0,
    active_seconds_4h integer default 0,
    active_seconds_8h integer default 0,
    active_seconds_12h integer default 0,
    active_seconds_24h integer default 0,
    active_seconds_48h integer default 0,
    active_seconds_72h integer default 0,
    active_after_soft_deadline_seconds integer default 0,
    primary key (game, player)
);
create index game_active_time_game_idx on game_active_time (game);

create table game_role (
    game text references game (id),
    faction_player text references player (username),
    email text, -- Conceptually references email (address), but not enforced
    faction text,
    faction_full text,
    action_required boolean,
    leech_required boolean,
    vp integer,
    rank integer,
    start_order integer,
    dropped boolean default false,
    primary key (game, faction)
);

create index game_role_faction_player_idx on game_role (faction_player);
create index game_role_email_idx on game_role (email);
create index game_role_game_idx on game_role (game);
create index game_role_action_required_idx on game_role (action_required);
create index game_role_leech_required_idx on game_role (leech_required);

create table blacklist (
       email text references email (address),
       player text references player (username)
);

create table game_note (
    game text references game (id),
    faction text,
    note text,
    author text references player(username),
    primary key (game, faction)
);

create table secret (
    secret bytea,
    shared_iv bytea,
    primary key (secret)
);

CREATE OR REPLACE FUNCTION uuid_generate_v4()
RETURNS uuid
AS '$libdir/uuid-ossp', 'uuid_generate_v4'
VOLATILE STRICT LANGUAGE C;

create table chat_message (
    id uuid not null default uuid_generate_v4(),
    game text references game (id),
    faction text,
    message text,
    posted_at timestamp default now(),
    posted_on_turn text,
    primary key (id)
);
create index chat_message_game_idx on chat_message (game);

create table chat_read (
    game text references game (id),
    player text references player (username),
    last_read timestamp,
    primary key (game, player)
);

create table player_ratings (
    player text references player (username),
    rating integer,
    primary key (player)
);

create table game_events (
    game text references game (id),
    events text,
    primary key (game)
);

-- Non-rules game options
create table game_options (
    game text references game (id),
    minimum_rating integer,
    maximum_rating integer,
    description text,
    deadline_hours integer default 168,
    chess_clock_hours_initial integer,
    chess_clock_hours_per_round integer,
    chess_clock_grace_period integer default 12,
    primary key (game)
);
