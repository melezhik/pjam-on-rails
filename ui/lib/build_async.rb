# coding: UTF-8

class BuildAsync < Struct.new( :project, :build )


    def perform
        pj = BuildPjam.new self, project, build
        pj.run 
    end

    def before(job)
        mark_build_as_processing
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

    def log method, line

        outline = line || ""
        log_data = build[:log] || ""
        line.chomp!
        if method == :error
            build.update( { :log => log_data + "\n" + "ERROR: #{outline}" } )
        elsif method == :warning
            build.update( { :log => log_data + "\n" + "WARN: #{outline}" } )
        elsif method == :debug
            build.update( { :log => log_data + "\n" + "DEBUG: #{outline}" } )
        else
            build.update( { :log => log_data + "\n" + "INFO: #{outline}" } )
        end
        build.save
    end

    def mark_build_as_processing
        build.update({ :state => 'processing' })
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
