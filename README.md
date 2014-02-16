# pjam-on-rails

Your perl applications builder. Yeah, this is the continues integration server for perl applications.

# Features
* creates perl applications builds 
* uses [pinto](https://github.com/thaljef/Pinto) inside to handle dependencies
* checkouts sources from subversion VCS 
* asynchronously executes build tasks
* sends builds notifications by jabber
* keeps artefacts
* shows differences between builds
* this is the ruby on rails application

# Installation

    git clone https://github.com/melezhik/pjam-on-rails.git
    cd pjam-on-rails/ui
    bundle install # install ruby dependencies
    nano config/database.yml # setup database backend 
    rake db:migrate # initialize database 
    ./bin/delayed_job start # start builds scheduler  
    rails server # start pjam server binded to 127.0.0.1:3000
  
# Prerequisites
- nodejs
- libmysql # variant for debian

# See also
- ruby on rails
- pinto

