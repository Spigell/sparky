use Proc::Q;

sub MAIN (
  Str  :$root = '/home/' ~ %*ENV<USER> ~ '/sparky-root', 
  Int  :$timeout = 360, 
)

{


  for dir($root) -> $dir {
        next unless "$dir/sparrowfile".IO ~~ :f;
        say "process {$dir.basename} ...";
        my $proc-chan = proc-q (("sparrowdo", "--sparrowfile=$dir/sparrowfile"),), timeout => $timeout;
        react whenever $proc-chan { say "{.out}" ~ (". Killed due to timeout" if .killed ) }
  }
  
} 



