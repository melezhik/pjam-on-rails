# coding: UTF-8

class BuildAsync < Struct.new( :project, :build, :settings )


    def perform
        pj = BuildPjam.new self, project, build, settings 
        pj.run 
    end

    def before(job) 
        mark_build_as_in_processing
        log :info, "scheduled async build for project ID:#{project.id} build ID:#{build.id}"
    end

    def after(job)
        log :info, "finished async build for project ID:#{project.id} build ID:#{build.id}"
    end

    def success(job)
        mark_build_as_succeeded
        log :info, "succeeded async build for project ID:#{project.id} build ID:#{build.id}"
    end        


    def error(job, ex)
             log :error, "#{ex.class} : #{ex.message}"
             log :error, ex.backtrace
    end

    def failure(job)
            mark_build_as_failed
    end

    def max_attempts
        return 1
    end

    def log level, chunk

        if chunk.class == Array
            log_chunk = chunk.join "\n"
        else
            log_chunk = chunk || ""
        end

        log_chunk.chomp!
        log_entry = build.logs.create
        log_entry.update( { :level => level, :chunk => log_chunk } )
        log_entry.save
        build.save
    end

    def mark_build_as_in_processing
        build.update({ :state => 'in processing' })
        build.save
    end

    def mark_build_as_failed
        build.update({ :state => 'failed' })
        build.save
    end

    def mark_build_as_succeeded
        build.update({ :state => 'succeeded' })
        build.save
    end

end
