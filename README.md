# SYNOPSIS

Sparky is a continues integration server based on Sparrow/Sparrowdo ecosystem.

# Build status

[![Build Status](https://travis-ci.org/melezhik/sparky.svg)](https://travis-ci.org/melezhik/sparky)


# Description

Sparky is heavily based on Sparrowdo, so I encourage you to read [Sparrowdo docs](https://github.com/melezhik/sparrowdo) first,
but if you're impatient I'll brief you.

## Installation

    $ git clone https://github.com/melezhik/sparky.git
    $ cd sparky && zef install .
    $ sudo apt-get install sqlite3
    $ perl6 db-init.pl6 --root=/home/$USER/.sparky/projects 

## Run daemon

You need to run the sparky daemon first pointing it a root directory with projects  

    $ sparkyd --root=/home/$USER/.sparky/projects

Sparky daemon will be building the projects found in the root directory.

Once a project gets built sparky worker (`sparky-runner.pl6`) sleeps for $timeout seconds. 

This eleminates surplus sparky workers runs.

You can change the timeout by applying `--timeout` parameter:

    $ sparkyd --root=/home/$USER/.sparky/projects --timeout=600 # sleep 10 minutes

Running in daemonized mode.

At the moment sparky can't daemonize itself, as temporary workaround use linux `nohup` command:

    $ nohup sparkyd &

## Create a project

It should be just a directory located at the sparky root:

    $ mkdir /home/$USER/.sparky/projects/bailador-app

## Define build scenario

It should sparrowdo scenario, for example we want to check out a source code from Git,
install dependencies and then run unit tests. Say it's going to be a Bailador project:

    $ nano /home/$USER/.sparky/projects/bailador-app/sparrowfile

    package-install 'git';
    
    bash q:to/HERE/;
      set -e;
      if test -d .git; then
        git pull
      else
        git clone https://github.com/Bailador/Bailador.git . 
      fi
    
    HERE
    
    zef 'Path::Iterator';
    zef '.', %( depsonly => True );
    zef 'TAP::Harness';
    
    bash 'export PATH=/opt/rakudo/share/perl6/site/bin/:/opt/rakudo/bin:$PATH && prove6 -l', %(
      debug => True
    );
    
## Set up executor

By default the build scenario gets executed _on the same machine you run sparky at_, but you can change this
to _any remote host_ providing sparrowdo related parameters, as sparky _uses_ sparrowdo to run build scenarios:

    $ nano /home/$USER/.sparky/projects/bailador-app/sparky.yaml

    sparrowdo:
      - host: '192.168.0.1'
      - ssh_private_key: /path/to/ssh_private/key.pem
      - ssh_user: sparky
      - no_index_update: true

You read about the all [available parameters](https://github.com/melezhik/sparrowdo#sparrowdo-client-command-line-parameters) in sparrowdo documentation.

## Run by cron

It's possible to setup scheduler for Sparky builds, you should define `crontab` entry in sparky yaml file.
for example to run a build every hour at 30,50 or 55 minute say this:

    $ nano /home/$USER/.sparky/projects/bailador-app/sparky.yaml

    crontab: "30,50,55 * * * *"


Follow [Time::Crontab](https://github.com/ufobat/p6-time-crontab) documentation on crontab entries format.

## See the reports

Right now reports are just static files and there is no dedicated API to view them.
However this is how you can see them by using nginx:

    $ sudo mkdir -p /var/www/html/sparky
    $ sudo chmod a+x /var/www/html/sparky
    $ sudo chmod a+w /var/www/html/sparky

    $ nano /etc/nginx/sites-enabled/default

    location /sparky {
      charset UTF-8;
      autoindex on;
    }

    $ sudo service nginx reload

    $ sparkyd --root /var/data/sparky --reports-root=/var/www/html/sparky

    $ firefox 127.0.0.1/sparky

## SQLite API

You may check builds statues and times in runtime via sqlite database created by sparky:

    $ sqlite3 $sparky-root/db.sqlite3 

    sqlite> .schema builds
    CREATE TABLE builds (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        project     varchar(4),
        state       int,
        dt datetime default current_timestamp
    );
    
    sqlite> select * from builds;

    26|test-project3|1|2017-06-30 11:21:05
    27|bailador-app|0|2017-06-30 11:21:05
    28|test-project|0|2017-06-30 11:21:05
    29|update-sparrow|1|2017-06-30 11:21:05
    30|test-project3|1|2017-06-30 11:22:58
    31|bailador-app|0|2017-06-30 11:22:58
    32|test-project|-1|2017-06-30 11:22:58
    33|update-sparrow|1|2017-06-30 11:22:58
    34|test-project3|0|2017-06-30 11:30:22
    35|bailador-app|0|2017-06-30 11:30:22
    36|test-project|0|2017-06-30 11:30:22
    37|update-sparrow|0|2017-06-30 11:30:23
    38|test-project3|0|2017-06-30 11:31:16
    39|bailador-app|0|2017-06-30 11:31:16
    40|test-project|0|2017-06-30 11:31:16
    41|update-sparrow|0|2017-06-30 11:31:16
    42|test-project3|1|2017-06-30 11:31:26
    43|bailador-app|0|2017-06-30 11:31:27
    44|test-project|-1|2017-06-30 11:31:27
    45|update-sparrow|1|2017-06-30 11:31:27
    

Field state has one of tther possible values:

* 0  - build is running
* 1  - build succeeded
* -1 - build failed

# Command line client

You build run a certain project using sparky command client called `sparky-runner.pl6`

    $ sparky-runner.pl6 --dir=/home/$USER/.sparky/projects/bailador-app/  --stdout

# Sparky runtime parameters

All this parameters could be overridden by command line ( `--root`, `--work-root`, `--reprots-root` )

##  Rood directory

This is directory where sparky looks for projects:

    /home/$USER/.sparky/projects/

##  Work directory

This is working directory where sparky might place some stuff, useless at the moment:

    /home/$USER/.sparky/work

##  Reports directory

This is working directory where sparky place reports:

    /home/$USER/.sparky/reports


# Sparrowdo runtime parameters

These parameters can't be overridden and should be treated as internal Sparrowdo stuff.

I list them here for documentation purposes only.

## SparrowRoot

  `/opt/sparky-sparrowdo/$project`

## SparrowCwd

  `/var/data/sparky/$project`

# See also

[Sparky-docker](https://github.com/melezhik/sparky-docker) - Run Sparky as Docker container.

# Author

Alexey Melezhik






