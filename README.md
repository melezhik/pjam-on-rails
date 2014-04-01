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

## Pinto repository root

Will be created in ~/.pjam/repo directory. To migrate existed one simply run following:

    mkdir -p  ~/.pjam/repo/ && cp -r /path/to/existed/repo/root  ~/.pjam/repo

## Arfefacts root

Will be created in ~/.pjam/projects directory. 

# Terminology

A brief explanation for pjam concept as terminology terms.
 
- Pjam - a name of build server. Pjam-on-rails - an "official" name, bear in mind
that an application is written on ruby on rails framework.
- Project - is the collection of sequential builds. Project describes a configuration to be applied to the next build to be run. Different builds may be compared.
- Build - is the result of pjam builder, every build has a state and if build is succeeded has a number of artefacts. Build "inherit" it's configuration from projects when it is scheduled to builds queue. Build describe how and which source code from  VCS  is being build.  
- Pjam builder - is the builds scheduler, which  asynchronously process the queue of builds, under the hood pjam builder implemented by active_job jam
- Artefacts - a number of files, data resulted in successful build. Actually an archive of Perl modules for an application to be installed.
 
# See also
- [pinto](https://github.com/thaljef/Pinto)
- [ruby on rails](http://rubyonrails.org)
- [subversion](http://subversion.tigris.org)

