sub MAIN (
  Str  :$root = '/home/' ~ %*ENV<USER> ~ '/sparky-root', 
  Int  :$timeout = 360, 
  Str  :$reports-root = '/home/' ~ %*ENV<USER> ~ '/sparky-reports', 
)

{

my %project-state;

  while (True) {

    for dir($root) -> $dir {

      next unless "$dir/sparrowfile".IO ~~ :f;
      my $project = $dir.basename;
  
      my $state = %project-state{$project} || 'unknown';
  
      if $state eq 'running' {
        #say "skip $project as it's already running ...";
        next;
      }
  
      say "run {$project} ...";
  
      my $p = Promise.start({ shell("sparrowdo --sparrowfile=$dir/sparrowfile > $reports-root/$project.txt 2>&1") });

      %project-state{$project}='running';
  
      $p.then({ %project-state{$project}='finished' }); 

    }
  }
} 



