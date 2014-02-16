# pjam-on-rails

Your perl applications builder. Yeah, this is a continues integration server for perl applications.

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
    nano config/databases.yml # setup database backend 
    rake db:migrate # initialize database
    bundle exec rake assets:precompile
    ./bin/delayed_job start # start builds scheduler  
    RAILS_ENV=production rails server -d # start pjam server binded to 127.0.0.1:3000
  
# Prerequisites
- nodejs
- libmysql # variant for debian

# Configuration
All you have to do is to setup database used as data backend. Choose any driver you like, but mysql is recommended for production usage:

    nano config/databases.yml
    cat config/databases.yml
    
    production:
        adapter: mysql
        database: pjam_data
        username: root
        password: supersecret
        host: localhost
    

# See also
- [pinto](https://github.com/thaljef/Pinto)
- [ruby on rails](http://rubyonrails.org)
- [subversion](http://subversion.tigris.org)
