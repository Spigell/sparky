use Bailador;
use DBIish;
use Text::Markdown;

my $root = %*ENV<SPARKY_ROOT> || '/home/' ~ %*ENV<USER> ~ '/.sparky/projects';
my $reports-root = %*ENV<SPARKY_REPORTS_ROOT> || '/home/' ~ %*ENV<USER> ~ '/.sparky/reports';

get '/' => sub {

  my $dbh = DBIish.connect("SQLite", database => "$root/db.sqlite3".IO.absolute );

  my $sth = $dbh.prepare(q:to/STATEMENT/);
      SELECT * FROM builds order by dt desc limit 100
  STATEMENT

  $sth.execute();

  my @rows = $sth.allrows(:array-of-hash);

  $sth.finish;

  $dbh.dispose;
  
  template 'builds.tt', @rows;   

}

get '/report/(\S+)/(\d+)' => sub ($project, $build_id) {
  if "$reports-root/$project/build-$build_id.txt".IO ~~ :f {
    template 'report.tt', $project, $build_id, "$reports-root/$project/build-$build_id.txt";
  } else {
    status(404);
  }
}

get '/about' => sub {

  my $raw-md = slurp "README.md";
  my $md = parse-markdown($raw-md);
  template 'about.tt', $md.to_html;
}

baile;

