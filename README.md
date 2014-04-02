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

# Glossary

A brief explanation for pjam concept in glossary way.
 
- `Pjam` - a name of the build server. Pjam-on-rails - a long, "official" name, bear in mind that pjam application is written on ruby on rails framework.

- `Application` - is arbitruary perl application. A `component` - is a part of application, an arbitrary source code stored in VCS. In pjam model an application is the _list_ of components. 
Components may also be treated as perl modules, but not necessarily should be perl modules. Every component should has valid Build.PL|Makefile.PL file.

- A pjam `dependency`. Is one of two types of things:
    - a CPAN module - get resolved from cpan repository
    - a component; a component of course may depend on CPAN modules

- Pjam `project` is and application _view_ in pjam GUI.

- `Build proccess` - the process of creation of distribution archive for an application. Schematically it does following
     - every component is visited, converted into pinto distirbution archive and added to pinto repository.
     - then every pinto distribution is installed into local directory - `build install base`
     - then build install base is archived - we have so called build artefact.


- Pjam `Build` is the snapshot for two types of things:
    - an application's componets list 
    - a pinto local repository - implimented as pinto stack

- Build has:
    - an install base - local directory with all of the dependencies for an application
    - a state : 'succeeded'|'failed'. Succeeded build means build process has finished successfully and build has a artefact.
    - an attached pinto stack, which represent all modules version installed into build install base

- Build `"inheritance"` . When build process starts:
    - project's components list is applied to build environment
    - new pinto stack is created as a copy of pinto stack of previous build
    - new install base is created as a copy of istall base of previous build
    - build is added to builds queue ( see note about build scheduler )

- `Sequences of builds`.  User change an application component's list and initiate build processes, which in  turn results in build sequences for given project. 
Different builds may be compared. 

- `Build scheduler` - asynchronous scheduler processing the build's queue. Build schediler uses delayed_job under the hood.

# See also
- [pinto](https://github.com/thaljef/Pinto)
- [ruby on rails](http://rubyonrails.org)
- [subversion](http://subversion.tigris.org)

