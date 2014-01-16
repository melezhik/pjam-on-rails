class BuildAsync < Struct.new( :project, :build  )

    def perform
        Delayed::Worker.logger.info "scheduled async build for project ID:#{project.id} build ID:#{build.id}"
        #projects.sources_ordered.select {|ss| ss[:state] == 'enabled' }.each  do |s|
        #     Delayed::Worker.logger.info  "process source: #{s[:url]}"
        #end
    end

    def success(job)
        Delayed::Worker.logger.info "successfully complited async build for project ID:#{project.id} build ID:#{build.id}"
    end        


    def error(job)
        Delayed::Worker.logger.info "errored async build"
    end

    def failure(job)
        Delayed::Worker.logger.info "failured async build for project ID:#{project.id} build ID:#{build.id}"
    end

    def max_attempts
        return 1
    end

end
