# pjam-on-rails

Continues Integration server for PERL applications.

# Features
* creates builds for perl applications using [pinto](https://github.com/thaljef/Pinto) 
* asynchronous execution of build tasks
* SCM integration ( subversion )
* sends builds notifications by jabber
* keeps artefacts
* shows changes of configuration settings and artefacts
* this is the ruby on rails application
* web ui powered by bootstrap


# Installation

    git clone https://github.com/melezhik/pjam-on-rails.git
    cd pjam-on-rails/ui
    bundle install # install ruby dependencies 
    rake db:migrate # create database 
    ./bin/delayed_job start # start builds scheduler  
    rails server # start as 127.0.0.1:3000
  
# Prerequisites
- nodejs
- mysql / sqlite client

# See also
- ruby on rails
- pinto

