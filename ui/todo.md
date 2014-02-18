# bugs
- bootstrap css does not work for production environment +
	- workaround:  
	bundle exec rake assets:precompile + config.serve_static_assets = true in config/environments/production.rb 
	http://stackoverflow.com/questions/17904949/rails-app-not-serving-assets-in-production-environment

# improvements
- use radio buttons instead of popup list when set project artefact
- build actions (delete, release, annotate, lock, unlock) should be recorded into project's history 
- cpanlib inheritance - replace project's cpanlib by ancestor build's cpanlib when starting new build 

# refactoring
- distribution_source should be renamed to application or arftefact ?

# fixes
- store jabber password incrypted ? 
- add PINTO_LOCKFILE_TIMEOUT to pjam environment ?

# new features
- delete all sources
- handle svn.exteranls - which result in multiple sources being added via single url
- copy project - copy cpanlib and pinto stack into new project from another project - I am not sure If I need this when I have one stack per one build ...
- lock project - forbid any project modifications
- ability to pin / upin / pull modules via pjam  ?
- add ldap authoriazation ?
- install distribution on client machine via http request to pjam
- new settings parameter - `PINTO_DEBUG' or `VERBOSE' 


