use YAMLish;
use DBIish;
use Time::Crontab;

sub MAIN (
  Str  :$dir = "$*CWD",
  Str  :$project = $dir.IO.basename,
  Str  :$reports-root = '/home/' ~ %*ENV<USER> ~ '/.sparky/reports',
  Bool :$stdout = False,
  Int  :$timeout = 10,
)
{

  sleep($timeout) unless ( $stdout or %*ENV<SPARKY_SKIP_CRON> );

  if "$dir/sparky.yaml".IO ~~ :f and ! $stdout and ! %*ENV<SPARKY_SKIP_CRON> {
    my %config = load-yaml(slurp "$dir/sparky.yaml");
    if %config<crontab> {
      my $crontab = %config<crontab>;
      my $tc = Time::Crontab.new(:$crontab);
      if $tc.match(DateTime.now, :truncate(True)) {
        say "$project is passed by cron: $crontab ...";
      } else {
        say "$project is skipped by cron: $crontab ... ";
        return;
      }
    }
  }

  mkdir $dir;

  mkdir "$reports-root/$project";

  my $dbh = DBIish.connect("SQLite", database => "$dir/../db.sqlite3".IO.absolute );

  my $sth = $dbh.prepare(q:to/STATEMENT/);
    INSERT INTO builds (project, state)
    VALUES ( ?,?)
  STATEMENT
  $sth.execute($project, 0);

  $sth = $dbh.prepare(q:to/STATEMENT/);
      SELECT max(ID) AS build_id
      FROM builds
      STATEMENT

  $sth.execute();

  my @rows = $sth.allrows();
  my $build_id = @rows[0][0];

  $sth.finish;

  say 'start sparrowdo for project: ' ~ $project ~ ' build ID:' ~ $build_id;

  my %config = Hash.new;

  if "$dir/sparky.yaml".IO ~~ :f {
    my %yaml-config = load-yaml(slurp "$dir/sparky.yaml");
    %config = %yaml-config<sparrowdo> if %yaml-config<sparrowdo>;
  }


  my $sparrowdo-run = "sparrowdo --sparrow_root=/opt/sparky-sparrowdo/$project";

  $sparrowdo-run ~= ' --no_color' unless $stdout;

  if %config<host> {
    $sparrowdo-run ~= " --host=" ~ %config<host>;
  } else {
    $sparrowdo-run ~= " --local_mode";
  }

  if %config<no_sudo> {
    $sparrowdo-run ~= " --no_sudo";
  }

  if %config<no_index_update> {
    $sparrowdo-run ~= " --no_index_update";
  }


  if %config<ssh_user> {
    $sparrowdo-run ~= " --ssh_user=" ~ %config<ssh_user>;
  }

  if  %config<ssh_private_key> {
    $sparrowdo-run ~= " --ssh_private_key=" ~ %config<ssh_private_key>;
  }

  if %config<ssh_port> {
    $sparrowdo-run ~= " --ssh_port=" ~ %config<ssh_port>;
  }

  if %config<http_proxy> {
    $sparrowdo-run ~= " --http_proxy=" ~ %config<http_proxy>;
  }

  if %config<https_proxy> {
    $sparrowdo-run ~= " --https_proxy=" ~ %config<https_proxy>;
  }

  if  %config<verbose> {
    $sparrowdo-run ~= " --verbose";
  }

  if ! $stdout {
    my $report-file = "$reports-root/$project/build-$build_id.txt";
    shell("$sparrowdo-run --task_run=directory" ~ '@path=' ~  "/var/data/sparky/$project --bootstrap 1>$report-file" ~ ' 2>&1');
    shell("echo >> $report-file && cd $dir && $sparrowdo-run --cwd=/var/data/sparky/$project 1>>$report-file" ~ ' 2>&1');
  } else{
    shell("$sparrowdo-run --task_run=directory" ~ '@path=' ~  "/var/data/sparky/$project --bootstrap"  ~ ' 2>&1');
    shell("echo && cd $dir && $sparrowdo-run --cwd=/var/data/sparky/$project" ~ ' 2>&1');
  }

  $dbh.do("UPDATE builds SET state = 1 WHERE ID = $build_id");

  say "project: $project build: $build_id finished";

  CATCH {


      # will definitely catch all the exception 
      default { 
        warn .say;
        say "project: $project build: $build_id failed";
        $dbh.do("UPDATE builds SET state = -1 WHERE ID = $build_id");
      }

  }


}

