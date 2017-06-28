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

## Create a project

It should be just a directory located at the sparky root:

    $ mkdir /var/data/sparky/perl6-app

## Define build scenario

It should sparrowdo scenario, for example we want to build Perl6 application and run unit tests:

    $ nano /var/data/sparky/perl6-app/sparrowfile

    zef '.', %( depsonly => True );

    bash 'prove6 -l';

## Set up SCM

You should set up source control resource so that sparky polls the changes and triggers the build scenario:

    
    $ nano /var/data/sparky/perl6-app/sparky.yaml

    scm: https://github.com/Bailador/Bailador.git

## Set up executor

By default the build scenario gets executed on the machine you run sparky at, but you can change this
providing sparrowdo related parameters, as sparky _uses_ sparrowdo to run build scenarios:

    $ nano /var/data/sparky/perl6-app/sparky.yaml

    sparrowdo:
      - host: 192.168.0.1
      - ssh_provate_key: /path/to/ssh_private/key.pem
      - ssh_user: sparky

You read about the all [available parameters](https://github.com/melezhik/sparrowdo#sparrowdo-client-command-line-parameters) in sparrowdo documentation.

## See the reports

    Just run you browser and find the reports related to the `perl6app` project 

    firefox 127.0.0.1:5000

# Author

Alexey Melezhik






