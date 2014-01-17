require 'term/ansicolor'

class BuildAsync < Struct.new( :project, :build  )

    extend Term::ANSIColor

    def perform
        log :info, "scheduled async build for project ID:#{project.id} build ID:#{build.id}"
        project.sources_ordered.select {|ss| ss[:state] == 't' }.each  do |s|
             log :info,  "process source: #{s[:url]}"
        end
        raise 'fail'
    end

    def after(job)
         log :info, "successfully schedulled async build for project ID:#{project.id} build ID:#{build.id}"
    end

    def success(job)
        log :info, "successfully complited async build for project ID:#{project.id} build ID:#{build.id}"
    end        


    #def error(job)
    #    log :error, "errored async build ):"
    #end

    def failure(job)
        log :error,  "failured async build for project ID:#{project.id} build ID:#{build.id} )))):"
    end

    def max_attempts
        return 1
    end

    def log method, line
        c = Term::ANSIColor
        if method == :error
            Delayed::Worker.logger.send( method, (c.red +  c.bold + line  + c.clear) )
        elsif method == :warning
            Delayed::Worker.logger.send( method, (c.brown +  c.bold + line  + c.clear) )
        elsif method == :debug
            Delayed::Worker.logger.send( method, (c.yellow +  c.bold + line  + c.clear) )
        else
            Delayed::Worker.logger.send( method, (c.green +  c.bold + line  + c.clear) )
        end
    end
end
