# bugs
- bootstrap css does not work for production environment +
	- workaround:  
	bundle exec rake assets:precompile + config.serve_static_assets = true in config/environments/production.rb 
	http://stackoverflow.com/questions/17904949/rails-app-not-serving-assets-in-production-environment

# fixes
- add time-stamp to artefacted archive's name 
- store jabber password incrypted ? 
- should apply PERL5LIB when creating distribution

# new features
- copy project - copy cpanlib and pinto stack into new project from another project
- lock project - forbide any project modifications and lock project's pinto stack
- compare 2 projects 
	- compare pinto stacks
	- compare projects configurations (sources list)
- package-list - show packages from pinto stack
- install distribution on client machine via http request to pjam
- history - store projects modifications in database and show them - who, what and when change in project
- pin / upin modules via pjam  ?
- ldap authoriazation ?

## settings
- PINTO_DEBUG or VERBOSE parameter?


