echo 'start sparky runner'

# sparrowdo --sparrowfile=$dir/sparrowfile --cwd=$work-root/$project  > $reports-root/$project.txt

sparrowdo --sparrowfile=$1 --cwd=$2  1>$3.txt &2>1

