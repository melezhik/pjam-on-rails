require 'fileutils'
require 'diff/lcs'
require 'diff/lcs/htmldiff'
require 'open3'

class BuildsController < ApplicationController


    def create

        @project = Project.find(params[:project_id])
        @build = @project.builds.create!

        make_snapshot @project, @build
        @project.history.create!( { :commiter => request.remote_host, :action => "run build ID: #{@build.id}" })

        Delayed::Job.enqueue(BuildAsync.new(@project, @build, Distribution, Setting.take, { :root_url => root_url, :public_path => Rails.public_path  } ),0, Time.zone.now ) 
        flash[:notice] = "build ID: #{@build.id} for project ID: #{params[:project_id]} has been successfully scheduled at #{Time.zone.now}"
        redirect_to project_path(@project)
    
    end

    def revert

        @project = Project.find(params[:project_id])
        @parent_build = Build.find(params[:id])

        if @parent_build.succeeded?

            @build = @project.builds.create!({ :parent_id => @parent_build.id })

            # remove all project's sources 
            @project.sources.each  do |s|
                indexed_url =  s._indexed_url
                s.destroy!
                @project.history.create!( { :commiter => request.remote_host, :action => "remove #{indexed_url}" })
            end

            # create new project's sources based on snapshot for parent build
            i = 0
            @parent_build.components.each do |cmp|
                i += 1    
                new_source = @project.sources.create({ :scm_type => cmp[:scm_type] , :url => cmp.url , :sn => i*2 })
                new_source.save!
                @project.history.create!( { :commiter => request.remote_host, :action => "add #{cmp.indexed_url}" })
                if cmp.main?
                    @project.update!({ :distribution_source_id => new_source.id })
                    @project.history.create!( { :commiter => request.remote_host, :action => "mark source ID: #{new_source.id}; indexed_url: #{cmp.indexed_url} as an main application component source for project ID: #{@project.id}" })
                end
            end

            # re-read project data from DB
            @project = Project.find(params[:project_id])

            make_snapshot @project, @build

            # override installbase by parent's install base
            FileUtils.rm_rf "#{@project.local_path}/cpanlib/"
            parent_cpanlib_path = "#{@project.local_path}/#{@parent_build.local_path}/artefacts/#{@parent_build[:distribution_name].sub('.tar.gz','')}/cpanlib/"
            FileUtils.cp_r "#{parent_cpanlib_path}", "#{@project.local_path}/"
            @project.history.create!( { :commiter => request.remote_host, :action => "override install base #{@project.local_path}/cpanlib by #{parent_cpanlib_path}" })

            settings = Setting.take
            copy_stack_cmd = "pinto --root=#{settings.pinto_repo_root} copy #{@project.id}-#{@parent_build.id} #{@project.id}-#{@build.id} --no-color"

            execute_command copy_stack_cmd
            @project.history.create!( { :commiter => request.remote_host, :action => copy_stack_cmd })

            @build.update({ :has_stack => true, :state => 'succeeded' })
            @build.save!

            FileUtils.mkdir_p "#{@project.local_path}/#{@build.local_path}/"
            FileUtils.cp_r "#{@project.local_path}/#{@parent_build.local_path}/artefacts/", "#{@project.local_path}/#{@build.local_path}/"

            @build.update({ :distribution_name => @parent_build[:distribution_name] })
            @build.save!

            @project.history.create!( { :commiter => request.remote_host, :action => "copy parent build data to new build: #{@project.local_path}/#{@parent_build.local_path}/artefacts/ -> #{@project.local_path}/#{@build.local_path}/" })

            @project.history.create!( { :commiter => request.remote_host, :action => "revert project to build ID: #{@parent_build.id}; new build ID: #{@build.id}" })

            flash[:notice] = "build ID: #{@build.id} for project ID: #{params[:project_id]} has been successfully reverted; parent build ID: #{@build.parent_id}"
        else
            flash[:alert] = "cannot revert project to unsucceded build; parent build ID:#{@parent_build.id}; state:#{@parent_build.state}"
        end

        redirect_to project_path(@project)

    end

    def show
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])
        @log_entries = @build.recent_log_entries
    end

    def configuration
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])
        @data = @build.snapshots
    end

    def edit
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])
    end

    def update 
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])
        
        if @build.update(builds_params)
            @project.history.create!( { :commiter => request.remote_host, :action => "annotate build ID: #{@build.id}" })
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

        if @precendent.nil?
            flash[:alert] = "cannot find precendent for build ID:#{@build.id}"
            redirect_to project_path(@project,@build)
        else

            @pinto_diff = execute_command("pinto --root=#{Setting.take.pinto_repo_root} diff #{@project.id}-#{@build.id} #{@project.id}-#{@precendent.id}  --no-color", false)
    
            Diff::LCS::HTMLDiff.can_expand_tabs = false
    
            s = StringIO.new
            
            if  @precendent.snapshots.empty?
                @snapshot_diff = "<pre>insufficient data for build ID: #{@precendent.id}</pre>"
            elsif  @build.snapshots.empty?
                @snapshot_diff = "<pre>insufficient data for build ID: #{@build.id}</pre>"
            else
                Diff::LCS::HTMLDiff.new( 
                    @precendent.components.map  { |cmp| ( cmp.main? ? '(app) ' : '' ) +  (cmp[:indexed_url] || 'NULL') }.sort, 
                    @build.components.map       {|cmp|  ( cmp.main? ? '(app) ' : '' ) +  (cmp[:indexed_url] || 'NULL') }.sort , 
                    :title => "diff #{@build.id} #{@precendent.id}" ,
                    :output => s
                ).run
    
                @snapshot_diff = s.string
                @snapshot_diff.sub!(/<html>.*<body>/m) { "" } 
                @snapshot_diff.gsub! '<h1>', '<strong>'
                @snapshot_diff.gsub! '</h1>', '</strong>'
                @snapshot_diff.sub! '</html>', ''
                @snapshot_diff.sub! '</body>', ''
    
            end

            @history = History.order( id: :desc ).where('project_id = ? AND created_at >= ?  AND created_at <= ? ', @project[:id], @precendent[:created_at], @build[:created_at] );

        end

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
            @project.history.create!( { :commiter => request.remote_host, :action => "delete build ID: #{params[:id]}" })
            flash[:notice] = "build ID:#{params[:id]} for project ID:#{params[:project_id]} has been successfully deleted"
        end
        redirect_to project_path(@project)

    end

    def release 
        @project = Project.find(params[:project_id])
        @build = Build.find(params[:id])

        
        if @build.update({ :released => true, :locked => true })
            flash[:notice] = "build ID:#{@build.id} has been successfully marked as released"
            @project.history.create!( { :commiter => request.remote_host, :action => "release build ID: #{@build.id}" })
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
            @project.history.create!( { :commiter => request.remote_host, :action => "lock build ID: #{@build.id}" })
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
            @project.history.create!( { :commiter => request.remote_host, :action => "unlock build ID: #{@build.id}" })
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

  def execute_command(cmd, raise_ex = true )
    res = []
    logger.debug "running command: #{cmd}"
    Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
        while line = stdout_err.gets
            logger.debug line
            res << line.chomp
        end
        exit_status = wait_thr.value
        retval = exit_status.success?
        unless exit_status.success?
          logger.debug "command failed"
          raise "command #{cmd} failed" if raise_ex == true
       end
    end
        logger.debug "command succeeded"
    res

  end

   def make_snapshot project, build
         # snapshoting current configuration before schedulling new build
         project.sources_enabled.each  do |s|
            cmp = build.snapshots.create!({ :indexed_url => s._indexed_url, :revision => s.last_rev  } )
            cmp.save!
            if project.distribution_indexed_url == s._indexed_url
                cmp.update!( { :is_distribution_url => true } )
                cmp.save!
            end
         end
   end  

end
