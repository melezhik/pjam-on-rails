# pjam-on-rails

Continues integration server for PERL.

# Features
* creates builds for perl applications using pinto 
* asynchronous execution of build tasks
* SCM integration ( subversion )
* sends builds notifications by jabber
* keeps artefacts
* this is the ruby on rails application
* simple, yet usefull gui powered by bootstrap
* keeps change logs for configuration settings - _todo_


# installation

    git clone https://github.com/melezhik/pjam-on-rails.git
    cd pjam-on-rails/ui
    rake db:migrate
    ./bin/delayed_job start  
    rails server
    # visit 127.0.0.1:3000
  
# prerequisites
- nodejs
- sqlite

  
  
