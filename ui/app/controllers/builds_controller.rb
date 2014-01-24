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
    end

    def destroy
        @project = Project.find(params[:project_id])
        build = Build.find(params[:id])
        FileUtils.rm_rf "#{@project.local_path}/#{build.local_path}"
        build.destroy
        flash[:notice] = "build # #{params[:id]} for project # #{params[:project_id]} has been successfully deleted"
        redirect_to project_path(@project)
    end


    def files   
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])
        send_file "#{@project.local_path}/#{@build.local_path}/artefacts/#{@build.distribution_name}"
    end

end
