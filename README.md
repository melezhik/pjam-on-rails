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
    rake db:migrate # initialize database
    bundle exec rake assets:precompile
    ./bin/delayed_job start # start builds scheduler  
    RAILS_ENV=production rails server -d # start pjam server binded to 127.0.0.1:3000
  
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
    
# Terminology

A brief explanation for pjam concept as terminology terms.
 
- Pjam - a name of build server. Pjam-on-rails - an "official" name, bear in mind
that an application is written on ruby on rails framework.
- Project - is the collection of sequential builds. Project describe a configuration to be applied to the next build to be run. Different builds may be compared.
- Build - is the result of pjam builder, every build has a state and if build is succeeded has a number of artefacts. Build "inherit" it's configuration from projects when it is scheduled to builds queue. Build describe how and which source code from  VCS  is being build.  
- Pjam builder - is the builds scheduler, which  asynchronously process the queue of builds, under the hood pjam builder implemented by active_job jam
- Artefacts - a number of files, data resulted in successful build. Actually an archive of Perl modules for an application to be installed.
 
# See also
- [pinto](https://github.com/thaljef/Pinto)
- [ruby on rails](http://rubyonrails.org)
- [subversion](http://subversion.tigris.org)
