# bugs
- bootstrap css does not work for production environment +
	- workaround:  
	bundle exec rake assets:precompile + config.serve_static_assets = true in config/environments/production.rb 
	http://stackoverflow.com/questions/17904949/rails-app-not-serving-assets-in-production-environment

# refactoring
- distribution_source should be renamed to application_id
- pull/add should be done in transactional way ( need to rewrite lib/build_pjam.rb )

# improvements
- activity log should show which project build belongs to 
- build.changes popuplist should show not only show ids, but build annotations  ( for easier build comparisons )

# fixes
- class names renamings
	- rename build_async.rb to build_create_async.rb
	- rename build_pjam.rb to build_create.rb
- store jabber password incrypted ? 
- add PINTO_LOCKFILE_TIMEOUT to pjam environment ?
- force_mode should be in project.settings instead of global.settings
- skip missing prerequisites should be in project.settings instead of global.settings

# new features

- sources.last_rev should be depricated and removed
- install distribution on client machine via http request to pjam
- delete all sources ( already done  in `revert build` function )
- handle svn.exteranls to allow add multiple sources as single url
- lock project - forbid any project modifications
- build purger - utility to delete old builds



