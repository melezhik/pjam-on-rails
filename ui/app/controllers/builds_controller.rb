require 'fileutils'
class BuildsController < ApplicationController


    def create

        @project = Project.find(params[:project_id])
        last_build = @project.builds.last
        @build = @project.builds.create
        @build.save
        Delayed::Job.enqueue(BuildAsync.new(@project, last_build, @build, Setting.take, { :root_url => root_url  } ),0, Time.zone.now) 
        flash[:notice] = "build # #{@build.id} for project # #{params[:project_id]} has been successfully scheduled at #{Time.zone.now}"
        redirect_to project_path(@project)
    
    end

    def show
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])
        @log_entries = @build.recent_log_entries
    end

    def edit
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])
    end

    def update 
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])
        
        if @build.update(builds_params)
            flash[:notice] = "build # #{@build.id} has been successfully annotated"
            redirect_to @project
        else
            flash[:alert] = "error has been occured when annotation build # #{@build.id}"
            render 'edit'
        end
    end


    def full_log
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])
        @log_entries = @build.all_log_entries
    end

    def destroy
        @project = Project.find(params[:project_id])
        build = Build.find(params[:id])

        _execute_command( "pinto --root=#{Setting.take.pinto_repo_root} kill #{@project.id}-#{build.id}", false)
        if build.locked?
            flash[:alert] = "cannot delete locked build! ID:#{params[:id]}"
        else
            FileUtils.rm_rf "#{@project.local_path}/#{build.local_path}"
            build.destroy
            flash[:notice] = "build # #{params[:id]} for project # #{params[:project_id]} has been successfully deleted"
        end
        redirect_to project_path(@project)

    end

    def lock
        @project = Project.find(params[:project_id])
        @build = @project.builds.find(params[:id])
        if @build.update({:locked => true })
            flash[:notice] = "build ID:#{params[:id]}; has been sucessfully locked"
            redirect_to [@project]
        else
            flash[:alert] = "error has been occured when locking build ID:#{params[:id]}"
            redirect_to [@project]
        end
    end

    def unlock
        @project = Project.find(params[:project_id])
        @build = @project.builds.find(params[:id])
        if @build.update({:locked => false })
            flash[:notice] = "build ID:#{params[:id]}; has been sucessfully unlocked"
            redirect_to [@project]
        else
            flash[:alert] = "error has been occured when unlocking build ID:#{params[:id]}"
            redirect_to [@project]
        end
    end

private

  def builds_params
      params.require( :build ).permit( :comment )
  end

  def _execute_command(cmd, raise_ex = true)
    retval = false
    Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
        while line = stdout_err.gets
            logger.debug line
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
