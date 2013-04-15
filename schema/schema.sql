create table player (
  username text primary key,
  password text
);

create table email (
  address text unique,
  player text references player (username),
  validated boolean
);

create table game (
    id text primary key,
    write_id text,
    needs_indexing boolean,
    finished boolean,
);

create table game_role (
    game text references game (id),
    email text, -- Conceptually references email (address), but not enforced
    faction text,
    boolean action_required,
    primary key (game, faction)
);



