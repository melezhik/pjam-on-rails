class ProjectsController < ApplicationController

    def new
        @project = Project.new
    end

    def create
        # render text: params[:project].inspect
        @project = Project.new project_params 
        if @project.save
            redirect_to @project
        else
            render 'new'
        end
    end

    def update 
        @project = Project.find(params[:id])
        
        if @project.update(project_params)
            redirect_to [:edit, @project]
        else
            render 'edit'
        end
    end

    def edit 
        @project = Project.find(params[:id])
    end

    def show
        @project = Project.find(params[:id])
    end

    def index
        @projects = Project.all
    end


    def destroy 
        @project = Project.find(params[:id])
        @project.destroy
        @message = "project # #{params[:id]} successfully deleted"
        render erb: @message
    end

private

  def project_params
      params.require(:project).permit(:title,:text)
  end

end
