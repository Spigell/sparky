sub MAIN (
  Str  :$dir,
  Str  :$project,
  Str  :$reports-root = '/home/' ~ %*ENV<USER> ~ '/.sparky/reports',
)
{

  mkdir $dir;

  mkdir $reports-root;

  say 'start sparrowdo for project ' ~ $project;

  shell("sparrowdo --task_run=directory" ~ '@path=' ~  "/var/data/sparky/$project --local_mode 1>$reports-root/$project.txt &2>1");

  shell("sparrowdo --sparrowfile=$dir/sparrowfile --cwd=/var/data/sparky/$project --local_mode 1>>$reports-root/$project.txt &2>1");

}
