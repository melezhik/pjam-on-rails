class BuildsController < ApplicationController


    def create

        @project = Project.find(params[:project_id])
        flash[:notice] = "build for project # #{params[:project_id]} successfully schedulled"
        redirect_to project_path(@project)
    
    end

end
