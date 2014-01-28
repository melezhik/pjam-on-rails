require 'fileutils'
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
        @log_entries = @build.recent_log_entries
    end

    def full_log
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])
        @log_entries = @build.all_log_entries
    end

    def destroy
        @project = Project.find(params[:project_id])
        build = Build.find(params[:id])
        FileUtils.rm_rf "#{@project.local_path}/#{build.local_path}"
        build.destroy
        flash[:notice] = "build # #{params[:id]} for project # #{params[:project_id]} has been successfully deleted"
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

end
