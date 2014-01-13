class SourcesController < ApplicationController

    def create
        @project = Project.find params[:project_id]
        @source = @project.sources.create( params[:source].permit( :url, :scm_type ) )
        redirect_to project_path @project
    end

    def destroy
        @project = Project.find(params[:project_id])
        @source = @project.sources.find(params[:id])
        @source.destroy
        redirect_to project_path(@project)
  end


end
