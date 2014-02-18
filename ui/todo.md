# bugs
- bootstrap css does not work for production environment +
	- workaround:  
	bundle exec rake assets:precompile + config.serve_static_assets = true in config/environments/production.rb 
	http://stackoverflow.com/questions/17904949/rails-app-not-serving-assets-in-production-environment
- Resolv.new.getname require read access to /etc/hosts - should fix it via Exception Handling

# improvements
- use radio buttons instead of popup list when set project artefact
- build actions (delete, release, annotate, lock, unlock) should be recorded into project's history 
- cpanlib inheritanse - replace project's cpanlib by ancestor build's cpanlib when starting new build 

# refactoring
- distribution_source should be renamed to application or arftefact ?

# fixes
- store jabber password incrypted ? 
- add PINTO_LOCKFILE_TIMEOUT to pjam environment 

# new features
- delete all sources

- copy project - copy cpanlib and pinto stack into new project from another project - I am not sure If I need this when I have one stack per one build
- lock project - forbid any project modifications
- pin / upin / pull modules via pjam  ?
- ldap authoriazation ?
- history - store projects modifications in database and show them - who, what and when change project
- install distribution on client machine via http request to pjam

## settings
- PINTO_DEBUG or VERBOSE parameter?


