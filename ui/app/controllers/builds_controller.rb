require 'fileutils'
require 'diff/lcs'
require 'diff/lcs/htmldiff'

class BuildsController < ApplicationController


    def create

        @project = Project.find(params[:project_id])
        @build = @project.builds.create!
        @build.save!

         # snapshoting current configuration before schedulling new build
         @project.sources_enabled.each  do |s|
            @build.snapshots.create({ :indexed_url => s._indexed_url } ).save!
         end

         @build.snapshots.create({ :indexed_url => @project.distribution_indexed_url, :is_distribution_url => true   } ).save!

        Delayed::Job.enqueue(BuildAsync.new(@project, @build, Distribution, Setting.take, { :root_url => root_url  } ),0, Time.zone.now ) 
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
            flash[:notice] = "build ID:#{@build.id} has been successfully annotated"
            redirect_to @project
        else
            flash[:alert] = "error has been occured when annotating build ID:#{@build.id}"
            render 'edit'
        end
    end

    def full_log
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])
        @log_entries = @build.all_log_entries
    end

    def list
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])
        @list = `pinto --root=#{Setting.take.pinto_repo_root} list -s #{@project.id}-#{@build.id} --no-color --format '%a/%f' | sort | uniq `.split "\n"
    end

    def changes

        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])


        if ! params[:build].nil? and  ! params[:build][:id].nil?
            @precendent =  Build.find(params[:build][:id]) 
        else
            @precendent =  @build.precedent 
        end

        @pinto_diff = `pinto --root=#{Setting.take.pinto_repo_root} diff #{@project.id}-#{@build.id} #{@project.id}-#{@precendent.id}  --no-color `.split "\n"

        Diff::LCS::HTMLDiff.can_expand_tabs = false

        s = StringIO.new
        
        Diff::LCS::HTMLDiff.new( 
            @precendent.snapshots.sort.map {|i| i[:indexed_url]}, 
            @build.snapshots.sort.map {|i| i[:indexed_url]} , 
            :title => "diff #{@build.id} #{@precendent.id}" ,
            :output => s
        ).run
        @snapshot_diff = s.string
    end

    def destroy
        @project = Project.find(params[:project_id])
        build = Build.find(params[:id])

        `pinto --root=#{Setting.take.pinto_repo_root} kill #{@project.id}-#{build.id}`

        if build.locked? or  build.released?
            flash[:alert] = "cannot delete locked  or released build! ID:#{params[:id]}"
        else
            FileUtils.rm_rf "#{@project.local_path}/#{build.local_path}"
            build.destroy
            flash[:notice] = "build # #{params[:id]} for project # #{params[:project_id]} has been successfully deleted"
        end
        redirect_to project_path(@project)

    end

    def release 
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])

        
        if @build.update({ :released => true, :locked => true })
            flash[:notice] = "build ID:#{@build.id} has been successfully marked as released"
            redirect_to @project
        else
            flash[:alert] = "error has been occured when trying to mark this build as released ID:#{@build.id}"
            render 'edit'
        end
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

end
