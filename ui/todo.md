# bugs
- bootstrap css does not work for production environment +
	- workaround:  
	bundle exec rake assets:precompile + config.serve_static_assets = true in config/environments/production.rb 
	http://stackoverflow.com/questions/17904949/rails-app-not-serving-assets-in-production-environment

- should handle invalid URLs when adding new source

# refactoring
- distribution_source should be renamed to application or arftefact ?
- pull/add should be done in transactional way

# improvements
- activity log should show which project build belongs to 
- rename rebuild to revert 
- rebuild build should also apply build sources ( required to add schema column to snapshots table )

# fixes
- store jabber password incrypted ? 
- add PINTO_LOCKFILE_TIMEOUT to pjam environment ?
- force_mode should be in project.settings instead of global.settings
- skip missing prerequisites should be in project.settings instead of global.settings
- when 

# new features
- apply build's configuration to project ?
- delete all sources
- handle svn.exteranls - which result in multiple sources being added via single url
- copy project - copy cpanlib and pinto stack into new project from another project - I am not sure If I need this when I have one stack per one build ...
- lock project - forbid any project modifications
- add ldap authoriazation ?
- install distribution on client machine via http request to pjam
- build purger - should delete old builds


