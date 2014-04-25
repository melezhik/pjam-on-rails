# bugs
- bootstrap css does not work for production environment +
	- workaround:  
	bundle exec rake assets:precompile + config.serve_static_assets = true in config/environments/production.rb 
	http://stackoverflow.com/questions/17904949/rails-app-not-serving-assets-in-production-environment

# core
- pull/add should be done in transactional way ( need to rewrite lib/build_pjam.rb )

# improvements
- need to higlight some log lines, may be this would require new log levels ( now it's error, debug, info )
- activity log should show which project build belongs to 
- build.changes popuplist should show not only show ids, but build annotations  ( for easier build comparisons )

# fixes
- column sources.last_rev should be depricated and removed
- class names renamings
	- rename build_async.rb to build_create_async.rb
	- rename build_pjam.rb to build_create.rb
- store jabber password incrypted ? 
- force_mode should be in project.settings instead of global.settings
- skip missing prerequisites should be in project.settings instead of global.settings
- distribution_source should be renamed to application_id

# new features
- `presets` - modules to be preinstalled to every distribution ( I am bothered with often missed dependencies )
- pjam files - project configuration in simple text format
- install distribution on client machine via http request to pjam
- delete all sources ( already done  in `revert build` function ) - may be replaced by pjam file
- lock project - forbid any project modifications



