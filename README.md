# pjam-on-rails

Pinto based build server for perl applications.

# Features
* creates perl applications builds 
* uses [pinto](https://github.com/thaljef/Pinto) inside to handle dependencies
* supports subversion and git SCMs
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
    rails server -d # start pjam server binded to 0.0.0.0:3000


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

# Gory details

This is a concise explanation for pjam object model.
 
## Pjam 

Is a name of the build server. Pjam-on-rails - a long, "official" name, bear in mind that pjam application is written on ruby on rails framework.

## Application

Is arbitruary perl application. 

## Component

Is a part of application, an arbitrary source code stored in VCS. In pjam model an application is the _list_ of components.  Components may also be treated as perl modules, but not necessarily should be perl modules. Every component should has valid Build.PL|Makefile.PL file, placed at component's root directory in VCS.

## Pjam dependency

This is the one of two types of things:

- a CPAN module - get resolved from cpan repository;
- a component; a component of course may depend on CPAN modules

## Pjam project  

Is and application _view_ in pjam GUI.

## Build proccess 

The process of creation of distribution archive for an application. Schematically it does following:

### Pinto phase

- every component in application list is visited, converted into pinto distirbution archive and added to pinto repository - this is called `pinto` phase.

### Compile pahse

- then every component's distribution achive is fetched from pinto repository and installed into local directory - `build install base` - this is called `compile` phase.

### Creating of artefacts

- then build install base is archived, archived build install base called artefact.

## Pjam build

Build is the "snapshot" of application ( the list of components ) plus some build's data. 

When the build starts project's components list is copied to build. The list of builds components is called `build configuration`.

### Build's data
The three type of things:
- an __install base__ - local directory with all of the application dependencies.
- an 'attached' __pinto stack__, which represents all module's versions installed into build install base.
- a __ build state__ - the build state, on of the following: `schedulled|processing|succeeded|failed`. Succeeded build state means build process has finished successfully and build has a artefact.

## Sequences of builds

This mechanism is described as  folows. User changes an application component's list and initiates the build processes resulting in build sequences for given project.  Different builds in the sequence may be compared. 

## Build "inheritance" 

The term of build inheritance may be described as follows. When build process starts:

- new pinto stack is created as a copy of pinto stack for previous build
- new install base is created as a copy of install base for previous build
- new build process is scheduled and build is added to builds queue ( see note about build scheduler )

## Build scheduler 

Is the asynchronous scheduler which processes the builds queue. Build schediler uses delayed_job under the hood.


# RESTfull API

Here I "drop" some common actions which may be done with restfull api as well

## copy build from one project to another project 

    curl -X POST http://your-pjam-server/projects/<project-id>/builds/<build-id>/revert -d '' -f -o /dev/null

- `build-id`    - the build ID which you want to copy 
- `project-id`  - the project ID where you want to copy build to


# PERL5LIB

- You may setup $PERL5LIB variable via pjam/settings/ page. Pjam will add PERL5LIB both to pinto and compile phases.

- Also be noticed, that pjam add $HOME/lib/perl5 to $PERL5LIB during pinto phase. That may be usefull when one want to use
(Module::Build, ExtUtils::MakeMaker or Module::Install ) which installed localy.


# See also
- [pinto](https://github.com/thaljef/Pinto)
- [ruby on rails](http://rubyonrails.org)
- [delayed jon](https://github.com/collectiveidea/delayed_job)

