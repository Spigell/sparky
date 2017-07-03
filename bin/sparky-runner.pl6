use YAMLish;
use DBIish;

sub MAIN (
  Str  :$dir!,
  Str  :$project = $dir.IO.basename,
  Str  :$reports-root = '/home/' ~ %*ENV<USER> ~ '/.sparky/reports',
  Bool :$stdout = False,
  Str  :$db,
  Int  :$build_id,

)
{

  mkdir $dir;

  mkdir "$reports-root/$project";

  say 'start sparrowdo for project: ' ~ $project ~ ' build ID:' ~ $build_id;

  my %config = Hash.new;

  if "$dir/sparky.yaml".IO ~~ :f {
    %config = load-yaml(slurp "$dir/sparky.yaml")<sparrowdo>;
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

  if $db and $build_id {
    my $dbh = DBIish.connect("SQLite", database => $db );
    $dbh.do("UPDATE builds SET state = 1 WHERE ID = $build_id");
  }

  say "project: $project build: $build_id finished";

  CATCH {


      # will definitely catch all the exception 
      default { 

        #.Str.say; 
        say "project: $project build: $build_id failed";

        if $db and $build_id {
          my $dbh = DBIish.connect("SQLite", database => $db );
          $dbh.do("UPDATE builds SET state = -1 WHERE ID = $build_id");
        }
  
      }

  }

}

