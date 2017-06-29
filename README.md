# SYNOPSIS

Sparky is a continues integration server based on Sparrow/Sparrowdo ecosystem.

# Build status

[![Build Status](https://travis-ci.org/melezhik/sparky.svg)](https://travis-ci.org/melezhik/sparky)


# Description

Sparky is heavily based on Sparrowdo, so I encourage you to read [Sparrowdo docs](https://github.com/melezhik/sparrowdo) first,
but if you're impatient I'll brief you.

## Run daemon

You need to run the sparky daemon first pointing it a root directory with projects  

    $ sparkyd --root /var/data/sparky

Sparky daemon will be building the projects found in the root directory every one minute.


## Create a project

It should be just a directory located at the sparky root:

    $ mkdir /var/data/sparky/bailador-app

## Define build scenario

It should sparrowdo scenario, for example we want to check out a source code from Git,
install dependencies and then run unit tests. Say it's going to be a Bailador project:

    $ nano /var/data/sparky/bailador-app/sparrowfile

    package-install 'git';

    bash(q:to/HERE/);
      set -e;
      if test -d .git; then
        git pull
      else
        git clone https://github.com/Bailador/Bailador.git . 
      fi

    HERE

    zef '.', %( depsonly => True );

    bash 'prove6 -l';


## Set up executor

By default the build scenario gets executed _on the same machine you run sparky at_, but you can change this
to _any remote host_ providing sparrowdo related parameters, as sparky _uses_ sparrowdo to run build scenarios:

    $ nano /var/data/sparky/bailador-app/sparky.yaml

    sparrowdo:
      - host: '192.168.0.1'
      - ssh_private_key: /path/to/ssh_private/key.pem
      - ssh_user: sparky

You read about the all [available parameters](https://github.com/melezhik/sparrowdo#sparrowdo-client-command-line-parameters) in sparrowdo documentation.

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

    $ sparkyd --root /var/data/sparky --reports-root=/var/www/html/sparky
  
    $ sudo service nginx reload

    $ firefox 127.0.0.1/sparky


# Author

Alexey Melezhik






