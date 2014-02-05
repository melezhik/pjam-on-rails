# pjam-on-rails

Continues Integration server for PERL applications.

# Features
* creates builds for perl applications using [pinto](https://github.com/thaljef/Pinto) 
* asynchronous execution of build tasks
* SCM integration ( subversion )
* sends builds notifications by jabber
* keeps artefacts
* keeps change logs for configuration settings - _todo_
* this is the ruby on rails application
* simple, yet usefull gui powered by bootstrap


# installation

    git clone https://github.com/melezhik/pjam-on-rails.git
    cd pjam-on-rails/ui
    bundle install
    rake db:migrate
    ./bin/delayed_job start  
    rails server # starts at 127.0.0.1:3000
  
# prerequisites
- nodejs
- sqlite or mysql client, depends on configuration




  
  
