# fixes
- drop initialzed column in projects table; I failed to do that with db:migrate engine

# improvements
- build logs should be multiple entries, inserts are faster than updates;
- show last 10-30 log entries when show build log; all logs are accessible by distinct link;


# features

## builds
- lock/unlock build 

## pinto
- pin / upin дистрибутива в проекте через пинтов
- показывать список пакетов, дистрибутивов через пинто

## initializer
- perl5lib может быть задана в инициализаторе
- default_cpan_mirror может быть задана в инициализаторе

