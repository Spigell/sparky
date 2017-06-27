sub MAIN (
  Str  :$root = '/home/' ~ %*ENV<USER> ~ '/sparky-root', 
  Int  :$timeout = 360, 
  Str  :$reports-root = '/home/' ~ %*ENV<USER> ~ '/sparky-reports', 
)
{

  react {
    sub run-project($dir, $project) {
      my $cmd = "sparrowdo --sparrowfile=$dir/sparrowfile > $reports-root/$project.txt 2>&1";
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
