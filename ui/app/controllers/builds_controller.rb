class BuildsController < ApplicationController


    def create

        @project = Project.find(params[:project_id])
        Delayed::Job.enqueue(BuildAsync.new, 1001, Time.zone.now) 
        flash[:notice] = "build for project # #{params[:project_id]} has been successfully scheduled at #{Time.zone.now};"
        redirect_to project_path(@project)
    
    end

end
