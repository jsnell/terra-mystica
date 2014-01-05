create table player (
  username text primary key,
  password text,
  displayname text,
  email_notify_turn boolean default true,
  email_notify_all_moves boolean default false,
  email_notify_chat boolen default true
);
create unique index player_username_lowercase_idx on player(lower(username));

create table email (
  address text unique,
  player text references player (username),
  is_primary boolean,
  validated boolean
);
create unique index email_address_lowercase_idx on email(lower(address));

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
    commands text,
    description text,
    game_options text array default '{}',
);

create table game_player (
    game text references game (id),
    player text references player (username),
    sort_key text,
    index integer,
    primary key (game, player, index)
);

create table game_role (
    game text references game (id),
    email text, -- Conceptually references email (address), but not enforced
    faction text,
    boolean action_required,
    boolean leech_required,
    vp integer,
    rank integer,
    start_order integer,
    primary key (game, faction)
);

create index game_role_email_idx on game_role (email);
create index game_role_game_idx on game_role (game);

create table blacklist (
       email text references email (address)
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
