require 'term/ansicolor'

class BuildAsync < Struct.new( :project, :build )

    extend Term::ANSIColor

    def perform
        log :info, "scheduled async build for project ID:#{project.id} build ID:#{build.id}"
        project.sources_ordered.select {|ss| ss[:state] == 't' }.each  do |s|
             log :info,  "process source: #{s[:url]}"
        end
        if (1 + Random.rand(11)).even?
            raise "random fail"
        end
    end

    def after(job)
    end

    def success(job)
        log :info, "successfully complited async build for project ID:#{project.id} build ID:#{build.id}"
        make_as_succeeded
    end        


    def error(job)
        log :error, "errored async build ):"
    end

    def failure(job)
        log :error,  "failured async build for project ID:#{project.id} build ID:#{build.id} )))):"
        make_as_failed
    end

    def max_attempts
        return 1
    end

    def log method, line
        c = Term::ANSIColor
        log_data = build[:log] || "\n"
        if method == :error
            build.update( { :log => log_data + "\n" + (c.red +  c.bold + line  + c.clear ) })
        elsif method == :warning
            build.update({ :log => log_data + "\n" + (c.brown +  c.bold + line  + c.clear ) }) 
        elsif method == :debug
            build.update({ :log => log_data + "\n" + (c.yellow +  c.bold + line  + c.clear ) }) 
        else
            build.update({ :log => log_data + "\n" + (c.green +  c.bold + line  + c.clear ) }) 
        end
        build.save
    end

    def make_as_failed
        build.update({ :state => 'failed' })
        build.save
    end

    def make_as_succeeded
        build.update({ :state => 'succeeded' })
        build.save
    end

end
