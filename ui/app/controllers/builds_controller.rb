class BuildsController < ApplicationController


    def create

        @project = Project.find(params[:project_id])
        @build = @project.builds.create
        @build.save
        Delayed::Job.enqueue(BuildAsync.new(@project, @build),0, Time.zone.now) 
        flash[:notice] = "build # #{@build.id} for project # #{params[:project_id]} has been successfully scheduled at #{Time.zone.now}"
        redirect_to project_path(@project)
    
    end

    def show
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])

    end

end
