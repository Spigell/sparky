use YAMLish;

sub MAIN (
  Str  :$dir,
  Str  :$project,
  Str  :$reports-root = '/home/' ~ %*ENV<USER> ~ '/.sparky/reports',
)
{

  mkdir $dir;

  mkdir $reports-root;

  say 'start sparrowdo for project ' ~ $project;

  my %config = Hash.new;

  if "$dir/sparky.yaml".IO ~~ :f {
    %config = load-yaml(slurp "$dir/sparky.yaml")<sparrowdo>;
  }

  my $sparrowdo-run = "sparrowdo --no_color --sparrow_root=/opt/sparky-sparrowdo/$project";

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


  shell("$sparrowdo-run --task_run=directory" ~ '@path=' ~  "/var/data/sparky/$project --bootstrap 1>$reports-root/$project.txt" ~ ' 2>&1');
  shell("$sparrowdo-run --sparrowfile=$dir/sparrowfile 1>>$reports-root/$project.txt" ~ ' 2>&1');

}
