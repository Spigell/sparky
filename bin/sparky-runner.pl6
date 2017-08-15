use YAMLish;
use DBIish;
use Time::Crontab;

state $DIR;
state $MAKE-REPORT;
state $TIMEOUT;

sub MAIN (
  Str  :$dir = "$*CWD",
  Bool :$make-report = False,
  Int  :$timeout = 10,
)
{

  $DIR = $dir;
  $MAKE-REPORT = $make-report;
  $TIMEOUT = $timeout;

  my $project = $dir.IO.basename;
  my $reports-dir = "$dir/../.reports/$project".IO.absolute;

  return unless "$dir/sparrowfile".IO ~~ :f;

  sleep($timeout) unless ( ! $make-report or %*ENV<SPARKY_SKIP_CRON> );

  my %config = Hash.new;

  if "$dir/sparky.yaml".IO ~~ :f {

    %config = load-yaml(slurp "$dir/sparky.yaml");

    if %config<disabled> and $make-report {
      say "$project build is disabled ... ";
      return;
    }

    if %config<crontab> and $make-report and ! %*ENV<SPARKY_SKIP_CRON> {
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

  my $build_id;

  my $dbh;



  if $make-report {

    mkdir $reports-dir;
  
    $dbh = DBIish.connect("SQLite", database => "$dir/../db.sqlite3".IO.absolute );
  
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
    $build_id = @rows[0][0];
  
    $sth.finish;
  
    say 'start sparrowdo for project: ' ~ $project ~ ' build ID:' ~ $build_id;

  } else {

    say 'start sparrowdo for project: ' ~ $project;

  }

  my $sparrowdo-run = "sparrowdo --sparrow_root=/opt/sparky-sparrowdo/$project";

  $sparrowdo-run ~= ' --no_color' unless ! $make-report;

  my %sparrowdo-config = %config<sparrowdo> || Hash.new;

  if %sparrowdo-config<host> {
    $sparrowdo-run ~= " --host=" ~ %sparrowdo-config<host>;
  } else {
    $sparrowdo-run ~= " --local_mode";
  }

  if %sparrowdo-config<no_sudo> {
    $sparrowdo-run ~= " --no_sudo";
  }

  if %sparrowdo-config<no_index_update> {
    $sparrowdo-run ~= " --no_index_update";
  }


  if %sparrowdo-config<ssh_user> {
    $sparrowdo-run ~= " --ssh_user=" ~ %sparrowdo-config<ssh_user>;
  }

  if  %config<ssh_private_key> {
    $sparrowdo-run ~= " --ssh_private_key=" ~ %config<ssh_private_key>;
  }

  if %sparrowdo-config<ssh_port> {
    $sparrowdo-run ~= " --ssh_port=" ~ %sparrowdo-config<ssh_port>;
  }

  if %sparrowdo-config<http_proxy> {
    $sparrowdo-run ~= " --http_proxy=" ~ %sparrowdo-config<http_proxy>;
  }

  if %sparrowdo-config<https_proxy> {
    $sparrowdo-run ~= " --https_proxy=" ~ %sparrowdo-config<https_proxy>;
  }

  if  %sparrowdo-config<verbose> {
    $sparrowdo-run ~= " --verbose";
  }

  if $make-report {
    my $report-file = "$reports-dir/build-$build_id.txt";
    shell("$sparrowdo-run --task_run=directory" ~ '@path=' ~  "/var/data/sparky/$project --bootstrap 1>$report-file" ~ ' 2>&1');
    shell("echo >> $report-file && cd $dir && $sparrowdo-run --cwd=/var/data/sparky/$project 1>>$report-file" ~ ' 2>&1');
  } else{
    shell("$sparrowdo-run --task_run=directory" ~ '@path=' ~  "/var/data/sparky/$project --bootstrap"  ~ ' 2>&1');
    shell("echo && cd $dir && $sparrowdo-run --cwd=/var/data/sparky/$project" ~ ' 2>&1');
  }

  if $make-report {
    $dbh.do("UPDATE builds SET state = 1 WHERE ID = $build_id");
    say "project: $project build: $build_id finished";
  } else {
    say "project: $project build finished";
  }


  CATCH {

      # will definitely catch all the exception 
      default { 
        warn .say;
        if $make-report {
          say "project: $project build: $build_id failed";
          $dbh.do("UPDATE builds SET state = -1 WHERE ID = $build_id");
        } else {
          say "project: $project build failed";
        }
      }

  }


  # remove old builds

  if %config<keep_builds> and $make-report {

    say "keep builds: " ~ %config<keep_builds>;

    my $sth = $dbh.prepare(q:to/STATEMENT/);
        SELECT ID from builds where project = ? order by id asc
    STATEMENT
    
    $sth.execute($project);
    
    my @rows = $sth.allrows();
  
    my $all-builds = @rows.elems;

    $sth.finish;

    my $remove-builds = $all-builds - %config<keep_builds>;

    if $remove-builds > 0 {
      my $i=0;
      for @rows -> @r {
        $i++;
        my $bid = @r[0];
        if $i <= $remove-builds {
          if $dbh.do("delete from builds WHERE ID = $bid") {
            say "remove build $project" ~ '@' ~ $bid;
          } else {
            say "!!! can't remove build $project" ~ '@' ~ $bid;
          }
          if unlink "$reports-dir/build-$bid.txt".IO {
            say "remove $reports-dir/build-$bid.txt";
          } else {
            say "!!! can't remove $reports-dir/build-$bid.txt";
          }
        }

      }

    }

  } 


}

LEAVE {
  if $MAKE-REPORT {

    say "re-run build for $DIR ... \n";
    shell(
      'sparky-runner.pl6' ~ 
      " --dir=$DIR" ~
      " --make-report" ~ 
      " --timeout=$TIMEOUT" ~
      ' &'
    ); 
  
  }
}
