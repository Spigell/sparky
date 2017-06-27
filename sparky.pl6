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
        run-project($dir, $project);
      }
    }
    
    for dir($root) -> $dir {
      next unless "$dir/sparrowfile".IO ~~ :f;
      run-project($dir, $dir.basename);
    }
  }
} 
