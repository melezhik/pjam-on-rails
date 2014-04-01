# pjam-on-rails

Perl build server. Yeah, this is a another continues integration server for Perl applications.

# Features
* creates perl applications builds 
* uses [pinto](https://github.com/thaljef/Pinto) inside to handle dependencies
* checkouts sources from subversion VCS
* both Makefile.PL, Build.PL systems support 
* asynchronously executes build tasks
* sends builds notifications by jabber
* keeps artefacts
* shows differences between builds
* show project activity logs
* this is a ruby on rails application


# Installation

    git clone https://github.com/melezhik/pjam-on-rails.git
    cd pjam-on-rails/ui
    bundle install # install ruby dependencies
    nano config/databases.yml # setup database backend 
    export RAILS_ENV=production
    rake db:migrate # initialize database
    bundle exec rake assets:precompile
    ./bin/delayed_job start # start builds scheduler  
    rails server -d # start pjam server binded to 127.0.0.1:3000


# Prerequisites
- nodejs
- libmysql 

# Configuration
All you need is to setup database configuration. Choose any driver you like, but mysql is recommended for production usage:

    nano config/databases.yml
    cat config/databases.yml
    
    production:
        adapter: mysql
        database: pjam_data
        username: root
        password: supersecret
        host: localhost


## None production/development configuration

For none production pjam usage you should omit exporting RAILS_ENV. In this case you may use sqlite database engine instead of mysql: 

    nano config/databases.yml
    cat config/databases.yml

    development:
        adapter: sqlite3
        database: db/development.sqlite3
        pool: 5
        timeout: 5000

    rake db:migrate # initialize database
    ./bin/delayed_job start # start builds scheduler  
    rails server -d # start pjam server binded to 127.0.0.1:3000

## Pinto repository root directory

Will be created in ~/.pjam/repo directory. To migrate existed one simply run following:

    mkdir -p  ~/.pjam/repo/ && cp -r /path/to/existed/repo/root  ~/.pjam/repo

## Artefacts root directory

Will be created in ~/.pjam/projects directory. 

# Terminology

A brief explanation for pjam concept.
 
- Pjam - a name of the build server. Pjam-on-rails - an "official" name, bear in mind that pjam application is written on ruby on rails framework.

- An application - is arbitruary perl application with source code checked out from VCS.

- Project describes an application build configuration. This configuration to be applied to next build to be run.  The configuration is the list of components. Every component is the represented by url in VCS.  Also project has a _main_ application component  which distribution is created from. Hereby components are just dependencies for an application to be build.

- Build is the result of build process run by user, when build starts:
    - project configuration is applied to build environment as components list
    - new pinto stacks is created as a copy of pinto stack of previous build
    - new install base is created as a copy of istall base of previous build
    - build is added to builds queue ( see note about build scheduler )

- Different builds may be compared. 

- Build scheduler - asynchronous scheduler processing the build's queue. Using delayed_job under the hood
- Artefacts - files created during the process of creating build
     - Install base - an local directory with all of the dependencies for application
     - Distribution archive - archived install base directory
 
# See also
- [pinto](https://github.com/thaljef/Pinto)
- [ruby on rails](http://rubyonrails.org)
- [subversion](http://subversion.tigris.org)

