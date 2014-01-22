class ProjectsController < ApplicationController

    def new
        @project = Project.new
    end

    def create
        # render text: params[:project].inspect
        @project = Project.new project_params 
        if @project.save
            flash[:notice] = "project # #{@project.id} has been successfully created"
            redirect_to @project
        else
            flash[:aler] = "error has been occured when creating project"
            render 'new'
        end
    end

    def update 
        @project = Project.find(params[:id])
        
        if @project.update(project_params)
            flash[:notice] = "project # #{@project.id} has been successfully updated"
            redirect_to [:edit, @project]
        else
            flash[:aler] = "error has been occured when updating project # #{@project.id} data"
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
        flash[:notice] = "project # #{@project.id} has been successfully removed"
        redirect_to controller: "projects"
    end

private

  def project_params
      params.require(:project).permit(:title,:text, :distribution)
  end

end
