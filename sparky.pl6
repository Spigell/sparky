use Proc::Q;

my $proc-chan = proc-q 
  (("sparrowdo", "--sparrowfile=/home/melezhik/projects/sparky-root/test-project/sparrowfile"),),
  timeout => 60
;

react whenever $proc-chan { say "{.out}" ~ (". Killed due to timeout" if .killed ) }
