create table player (
  username text primary key,
  password text
);
create unique index player_username_lowercase_idx on player(lower(username));

create table email (
  address text unique,
  player text references player (username),
  validated boolean
);
create unique index email_address_lowercase_idx on email(lower(address));

create table game (
    id text primary key,
    write_id text,
    needs_indexing boolean,
    finished boolean,
    exclude_from_stats boolean,
    last_update timestamp,
    player_count integer,
    round integer,
    commands text
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
    primary key (game, faction)
);

create table secret (
    secret bytea,
    shared_iv bytea,
    primary key (secret)
);

