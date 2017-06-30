use v6;
use DBIish;

my $sparky-root = '/home/' ~ %*ENV<USER> ~ '/.sparky';

mkdir $sparky-root;

my $db-name = "$sparky-root/db.sqlite3";

my $dbh = DBIish.connect("SQLite", database => $db-name );

my $sth = $dbh.do(q:to/STATEMENT/);
    DROP TABLE IF EXISTS builds
    STATEMENT

$sth = $dbh.do(q:to/STATEMENT/);
    CREATE TABLE builds (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        project     varchar(4),
        state       int,
        dt datetime default current_timestamp
    )
    STATEMENT


