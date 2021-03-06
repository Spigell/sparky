use YAMLish;
use DBIish;
use Time::Crontab;
use Data::Dump;

state $DIR;
state $MAKE-REPORT;

state %CONFIG;
state $SPARKY-BUILD-STATE;
state $SPARKY-PROJECT;
state $SPARKY-BUILD-ID;

sub MAIN (
  Str  :$dir = "$*CWD",
  Bool :$make-report = False,
  Str  :$marker
)
{

  $DIR = $dir;

  $MAKE-REPORT = $make-report;

  my $project = $dir.IO.basename;

  $SPARKY-PROJECT = $project;

  my $reports-dir = "$dir/../.reports/$project".IO.absolute;

  my %config = read-config($dir);

  mkdir $dir;

  my $build_id;

  my $dbh;

  if $make-report {

    mkdir $reports-dir;
  
    $dbh = get-dbh( $dir );
  
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
  
    $SPARKY-BUILD-ID = $build_id;

    say "RUN BUILD $project" ~ '@' ~ $build_id;

  } else {

    say "RUN BUILD <$project>";

  }

  my $sparrowdo-run = "sparrowdo --sparrow_root=/opt/sparky-sparrowdo/$project";

  $sparrowdo-run ~= ' --no_color' unless ! $make-report;

  my %sparrowdo-config = %config<sparrowdo> || Hash.new;

  if %sparrowdo-config<docker> {
    $sparrowdo-run ~= " --docker=" ~ %sparrowdo-config<docker>;
  } elsif %sparrowdo-config<host> {
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

  if %sparrowdo-config<format> {
    $sparrowdo-run ~= " --format=" ~ %sparrowdo-config<format>;
  } else {
    $sparrowdo-run ~= " --format=production";
  }

  if %sparrowdo-config<ssh_user> {
    $sparrowdo-run ~= " --ssh_user=" ~ %sparrowdo-config<ssh_user>;
  }

  if  %sparrowdo-config<ssh_private_key> {
    $sparrowdo-run ~= " --ssh_private_key=" ~ %sparrowdo-config<ssh_private_key>;
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

  %sparrowdo-config<bootstrap> = True unless %sparrowdo-config<bootstrap>:exists;

  if  %sparrowdo-config<bootstrap> {
    $sparrowdo-run ~= " --bootstrap";
  }

  if $make-report {
    my $report-file = "$reports-dir/build-$build_id.txt";
    shell("$sparrowdo-run --task_run=directory" ~ '@path=' ~  "/var/data/sparky/$project 1>$report-file" ~ ' 2>&1');
    shell("echo >> $report-file && cd $dir && $sparrowdo-run --cwd=/var/data/sparky/$project 1>>$report-file" ~ ' 2>&1');
  } else{
    shell("$sparrowdo-run --task_run=directory" ~ '@path=' ~  "/var/data/sparky/$project"  ~ ' 2>&1');
    shell("echo && cd $dir && $sparrowdo-run --cwd=/var/data/sparky/$project" ~ ' 2>&1');
  }


  if $make-report {
    $dbh.do("UPDATE builds SET state = 1 WHERE id = $build_id");
    say "BUILD SUCCEED $project" ~ '@' ~ $build_id;
    $SPARKY-BUILD-STATE="OK";
  } else {
    $SPARKY-BUILD-STATE="OK";
    say "BUILD SUCCEED <$project>";

  }

  CATCH {

      # will definitely catch all the exception 
      default { 
        warn .say;
        if $make-report {
          say "BUILD FAILED $project" ~ '@' ~ $build_id;
          $dbh.do("UPDATE builds SET state = -1 WHERE id = $build_id");
          $SPARKY-BUILD-STATE="FAILED";

        } else {
          say "BUILD FAILED <$project>";
          $SPARKY-BUILD-STATE="FAILED";
        }
      }

  }


  # remove old builds

  if %config<keep_builds> and $make-report {

    say "keep builds: " ~ %config<keep_builds>;

    my $sth = $dbh.prepare(q:to/STATEMENT/);
        SELECT id from builds where project = ? order by id asc
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
          if $dbh.do("delete from builds WHERE id = $bid") {
            say "remove build $project" ~ '@' ~ $bid;
          } else {
            say "!!! can't remove build <$project>" ~ '@' ~ $bid;
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

sub get-dbh ( $dir ) {

  my $conf-file = %*ENV<USER> ?? '/home/' ~ %*ENV<USER> ~ '/sparky.yaml' !! ( '/sparky.yaml' );

  my %conf = $conf-file.IO ~~ :e ?? load-yaml(slurp $conf-file) !! Hash.new;

  my $dbh;

  if %conf<database> && %conf<database><engine> && %conf<database><engine> !~~ / :i sqlite / {

    $dbh  = DBIish.connect(
        %conf<database><engine>,
        host      => %conf<database><host>,
        port      => %conf<database><port>,
        database  => %conf<database><name>,
        user      => %conf<database><user>,
        password  => %conf<database><pass>,
    );

  } else {

    $dbh  = DBIish.connect("SQLite", database => "$dir/../db.sqlite3".IO.absolute  );

  }

}

sub read-config ( $dir ) {

  my %config = Hash.new;

  if "$dir/sparky.yaml".IO ~~ :f {
    my $yaml-str = slurp "$dir/sparky.yaml";
    $yaml-str ~~ s:g/'%' BUILD '-' ID '%'/$SPARKY-BUILD-ID/  if $SPARKY-BUILD-ID;
    $yaml-str ~~ s:g/'%' BUILD '-' STATE '%'/$SPARKY-BUILD-STATE/ if $SPARKY-BUILD-STATE;
    $yaml-str ~~ s:g/'%' PROJECT '%'/$SPARKY-PROJECT/ if $SPARKY-PROJECT;
    %config = load-yaml($yaml-str);
    
  }

  return %config;

}

LEAVE {

  # Run Sparky plugins

  my %config =  read-config($DIR);

  if  %config<plugins> {
    my $i =  %config<plugins>.iterator;
    for 1 .. %config<plugins>.elems {
      my $plg = $i.pull-one;
      my $plg-name = $plg.keys[0];
      my %plg-params = $plg{$plg-name}<parameters>;
      my $run-scope = $plg{$plg-name}<run_scope> || 'anytime'; 

      #say "$plg-name, $run-scope, $SPARKY-BUILD-STATE";
      if ( $run-scope eq "fail" and $SPARKY-BUILD-STATE ne "FAILED" ) {
        next;
      }

      if ( $run-scope eq "success" and $SPARKY-BUILD-STATE ne "OK" ) {
        next;
      }

      say "Load Sparky plugin $plg-name ...";
      require ::($plg-name); 
      say "Run Sparky plugin $plg-name ...";
      ::($plg-name ~ '::&run')(
          { 
            project => $SPARKY-PROJECT, 
            build-id => $SPARKY-BUILD-ID,  
            build-state => $SPARKY-BUILD-STATE,
          }, 
          %plg-params
      );
  
    }
  }

  say ">>>>>>>>>>>>>>>>>>>>>>>>>>>";
  say "BUILD SUMMARY";
  say "STATE: $SPARKY-BUILD-STATE";
  say "PROJECT: $SPARKY-PROJECT";
  say "CONFIG: " ~ Dump(%config, :color(!$MAKE-REPORT));
  say ">>>>>>>>>>>>>>>>>>>>>>>>>>>";


  # run downstream project
  if %config<downstream> {
  
    say "SCHEDULE BUILD for DOWNSTREAM project <" ~ %config<downstream> ~ "> ... \n";

    my $downstream_dir = ("$DIR/../" ~ %config<downstream>).IO.absolute;

    if $MAKE-REPORT {
      shell(
        'sparky-runner.pl6' ~ 
        " --marker=$SPARKY-PROJECT" ~ 
        " --dir=" ~ $downstream_dir ~
        " --make-report" ~ 
        ' &'
      ); 
    } else {
      shell(
        'sparky-runner.pl6' ~ 
        " --marker=$SPARKY-PROJECT" ~ 
        " --dir=" ~ $downstream_dir ~
        ' &'
      ); 
    }

  }

}
