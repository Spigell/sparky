sub MAIN (
  Str  :$root = '/home/' ~ %*ENV<USER> ~ '/.sparky/projects', 
  Str  :$work-root = '/home/' ~ %*ENV<USER> ~ '/.sparky/work', 
  Str  :$reports-root = '/home/' ~ %*ENV<USER> ~ '/.sparky/reports', 
)
{

  constant SPARKY_RUNNER = %?RESOURCES<sparky-runner.sh>.Str;
  
  react {

    mkdir $root;
    mkdir $work-root;
    mkdir $reports-root;

    sub run-project($dir, $project) {

      mkdir "$work-root/$project";

      my $cmd = "sparky-runner.sh $dir/sparrowfile $work-root/$project $reports-root/$project.txt";

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
