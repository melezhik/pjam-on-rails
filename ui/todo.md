# bugs
- bootstrap css does not work for production environment +
	- workaround:  
	bundle exec rake assets:precompile + config.serve_static_assets = true in config/environments/production.rb 
	http://stackoverflow.com/questions/17904949/rails-app-not-serving-assets-in-production-environment

# fixes
- store jabber password incrypted ? 
- add PINTO_LOCKFILE_TIMEOUT to pjam environment
- chomp and delete '/' on the end of SRM urls  when writting to distribution table 


# new features
- delete project should also kill all stacks related to project's builds?
- copy project - copy cpanlib and pinto stack into new project from another project - I am not sure If I need this when I have one stack per one build
- lock project - forbide any project modifications ?
- lock build should also lock build's stack
- compare 2 projects - I am not sure If I need this when I may compare builds ... Also I may put current project configuration into the build 
	- compare pinto stacks
	- compare projects configurations (sources list)
- package list - show packages ( from pinto stack ) for given build 
- release  - mark build as released on production, which in turn make build locked
- pin / upin modules via pjam  ?
- ldap authoriazation ?
- history - store projects modifications in database and show them - who, what and when change project
- install distribution on client machine via http request to pjam

## settings
- PINTO_DEBUG or VERBOSE parameter?


