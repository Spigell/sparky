sub MAIN (
  Str  :$root = '/home/' ~ %*ENV<USER> ~ '/.sparky/projects', 
  Str  :$work-root = '/home/' ~ %*ENV<USER> ~ '/.sparky/work', 
  Str  :$reports-root = '/home/' ~ %*ENV<USER> ~ '/.sparky/reports', 
)
{

  
  react {

    mkdir $root;
    mkdir $work-root;
    mkdir $reports-root;

    sub run-project($dir, $project) {

      mkdir "$work-root/$project";

      my $cmd = "sparrowdo --sparrowfile=$dir/sparrowfile --cwd=$work-root/$project  > $reports-root/$project.txt 2>&1";
      whenever Proc::Async.new('/bin/sh', '-c', $cmd).start {
        run-project($dir, $project) if "$dir/sparrowfile".IO ~~ :f;
      }
    }
    
    sub add-dirs() {
      state %seen;
      for dir($root) -> $dir {
        next if %seen{$dir}++;
        next unless "$dir/sparrowfile".IO ~~ :f;
        run-project($dir, $dir.basename);
      }
    }
    
    whenever IO::Notification.watch-path($root) {
      add-dirs();
    }

    add-dirs();
  }
} 
