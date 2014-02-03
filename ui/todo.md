# bugs
- bug with '<table cellpadding="2" cellspacing="2" border="0">'
- notifications do not work for firewalled hosts
- bootstrap css does not work for production environment

# fixes
- drop initialized column in projects table; I failed to do that with db:migrate engine +
- drop jabber_server column in settings table +
- current.txt no longer need
- add time-stamp to artefacted archive name 

# improvements
- build logs should be multiple entries, inserts are faster than updates; +
- show last 10-30 log entries when show build log; all logs are accessible by distinct link; +
- update settings page - do not update jabber password if it is not set +

# features

## builds
- lock/unlock build +

## pinto
- pin / upin дистрибутива в проекте через пинтов
- показывать список пакетов, дистрибутивов через пинто

## settings
- задавать PINTO_DEBUG

