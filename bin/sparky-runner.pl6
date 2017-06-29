sub MAIN (
  Str  :$dir,
  Str  :$project,
  Str  :$reports-root = '/home/' ~ %*ENV<USER> ~ '/.sparky/reports',
)
{

  mkdir $dir;

  mkdir $reports-root;

  say 'start sparrowdo for project ' ~ $project;

  shell("sparrowdo --sparrow_root=/opt/sparrowdo/$project --task_run=directory" ~ '@path=' ~  "/var/data/sparky/$project --local_mode 1>$reports-root/$project.txt");
  shell("sparrowdo --sparrow_root=/opt/sparrowdo/$project --sparrowfile=$dir/sparrowfile --cwd=/var/data/sparky/$project --local_mode 1>$reports-root/$project.txt");

}
