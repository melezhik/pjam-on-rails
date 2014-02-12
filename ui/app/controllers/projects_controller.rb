require 'open3'

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
            flash[:alert] = "error has been occured when creating project"
            render 'new'
        end
    end

    def update 
        @project = Project.find(params[:id])
        
        if @project.update(project_params)
            flash[:notice] = "project # #{@project.id} has been successfully updated"
            redirect_to [:edit, @project]
        else
            flash[:alert] = "error has been occured when updating project ID:#{@project.id} data"
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

    def copy
        @project = Project.find(params[:id])

       # @project_copy = Project.new
       # @project_copy.update({ :title => @project.title + '-' + Time.new.to_i.to_s, :text => @project.text })

       # if @project_copy.save
       #     flash[:notice] = "new project ID:#{@project_copy.id} has been successfully created as copy of ID:#{@project.id}"
       # else
       #     flash[:alert] = "error has been occured when copy project:  #{@project_copy.errors.full_messages.join ' '}"
       # end

        flash[:alert] = "`copy project' feature is temporary disabled"
        redirect_to controller: "projects"
    end

    def destroy 
        @project = Project.find(params[:id])

        #@project.destroy
        #flash[:notice] = "project ID:#{@project.id} has been successfully removed"
        #redirect_to controller: "projects"

        flash[:alert] = "`destroy project' feature is temporary disabled"
        redirect_to controller: "projects"

    end

    def last_successfull_build
        @project = Project.find(params[:id])
        render text: root_url + 'projects/' + "#{@project.id}" + '/builds/' + "#{@project.last_successfull_build.id}" +  '/artefacts/' + @project.last_successfull_build.distribution_name
    end


private

  def project_params
      params.require(:project).permit( 
            :title, :text, 
            :distribution_source_id,
            :notify, 
            :recipients
     )
  end

  def _execute_command(cmd, raise_ex = true)
    retval = false
    Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
        while line = stdout_err.gets
            logger :debug, line
        end
        exit_status = wait_thr.value
        retval = exit_status.success?
        unless exit_status.success?
          raise "command #{cmd} failed" if raise_ex == true
       end
    end
    retval
 end

end
