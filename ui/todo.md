# bugs
- bootstrap css does not work for production environment +
	- workaround:  
	bundle exec rake assets:precompile + config.serve_static_assets = true in config/environments/production.rb 
	http://stackoverflow.com/questions/17904949/rails-app-not-serving-assets-in-production-environment
- `build changes` for very first build raise and error

# refactoring
- distribution_source should be renamed to application_id
- pull/add should be done in transactional way ( need to rewrite lib/build_pjam.rb )

# improvements
- it'd be good to apply build to anothe project - the as revert build in the project, but for another project - good basis for easy build branches (dev/stage/production)
- activity log should show which project build belongs to 
- remove `copy project` notions from code

# fixes
- store jabber password incrypted ? 
- add PINTO_LOCKFILE_TIMEOUT to pjam environment ?
- force_mode should be in project.settings instead of global.settings
- skip missing prerequisites should be in project.settings instead of global.settings

# new features
- install distribution on client machine via http request to pjam
- delete all sources ( already done  in `revert build` function )
- handle svn.exteranls to allow add multiple sources as single url
- lock project - forbid any project modifications
- add ldap authoriazation ?
- build purger - should delete old builds


