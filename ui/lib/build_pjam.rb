require 'fileutils'
require 'open3'

class BuildPjam < Struct.new( :build_async, :project, :build, :distributions, :settings, :env  )

    def run

         build_async.log :debug,  "settings.verbose: #{project[:verbose]}"
         build_async.log :debug,  "settings.force_mode: #{settings[:force_mode]}"
         build_async.log :debug,  "settings.pinto_repo_root: #{settings.pinto_repo_root}"
         build_async.log :debug,  "settings.skip_missing_prerequisites: #{settings.skip_missing_prerequisites || 'not set'}"
         build_async.log :debug,  "build ancestor: #{build.has_ancestor? ? build.ancestor.id : 'not set'}"

         _initialize

         raise "main application component not found for this build" unless build.has_main_component?
         build_async.log :debug,  "main application component found: #{build.main_component[:indexed_url]}"
  
             distributions_list = []
             final_distribution_archive = nil
             final_distribution_revision = nil


             if build.has_ancestor?
                 ancestor_cpanlib_path = "#{project.local_path}/#{build.ancestor.local_path}/cpanlib/*"
                 _execute_command  "cp -r #{ancestor_cpanlib_path} #{project.local_path}/#{build.local_path}/cpanlib/"
                 build_async.log :debug, "copied ancestor cpanlib path: #{ancestor_cpanlib_path} to #{project.local_path}/#{build.local_path}/cpanlib"
             else
                 FileUtils.mkdir_p "#{project.local_path}/#{build.local_path}/cpanlib/"
                 _execute_command  "touch #{project.local_path}/#{build.local_path}/cpanlib/exists"
                 build_async.log :debug, "build has no ancestor, just create #{project.local_path}/#{build.local_path}/cpanlib"
             end

             build.components.each  do |cmp|

                 build_async.log :info,  "processing component: #{cmp[:indexed_url]}"
    
                 FileUtils.rm_rf "#{project.local_path}/#{build.local_path}/#{cmp.local_path}"
                 FileUtils.mkdir_p "#{project.local_path}/#{build.local_path}/#{cmp.local_path}"
                 build_async.log :debug,  "component's local path: #{project.local_path}/#{build.local_path}/#{cmp.local_path} has been successfully created"
    
                 if build.has_ancestor? and record = build.ancestor.component_by_indexed_url(cmp[:indexed_url])
                        cmp.update!({ :revision => record[:revision] })
                        cmp.save!
                        build_async.log :debug, "found revsion: #{record[:revision]} in ancestor build for component: #{cmp[:indexed_url]}"
                 end
        
                 # construct scm specific object for component 
                 scm_handler = SCM::Factory.create cmp, "#{project.local_path}/#{build.local_path}/#{cmp.local_path}"

                 build_async.log :debug,  "component's scm hanlder class: #{scm_handler.class}"

                 _execute_command scm_handler.checkout_cmd

                 rev = scm_handler.last_revision

                 build_async.log :debug,  "last revision extracted from repoisitory: #{rev}"
                    
                 if (! cmp.revision.nil? and ! rev.nil?  and ! cmp.main? and cmp.revision == rev  and settings.force_mode == false )
    	 	        build_async.log :debug, "this component is already installed at revision: #{rev}, skip ( enable settings.force_mode to change this )"
	    	        next
    	         end
    
                 if (! cmp.revision.nil? and ! rev.nil? )
                    build_async.log :debug,  "changes found for #{cmp.url} between #{rev} and #{cmp.revision}"
                    _execute_command scm_handler.changes_cmd rev
                    _execute_command scm_handler.diff_cmd rev
                 end
	    
        	     pinto_distro_rev =  "#{rev}-#{build.id}"


                 build_async.log :debug, "component's source code has been successfully checked out"
                 
                 if ( ! cmp.main? and record = distributions.find_by(indexed_url: cmp.indexed_url, revision: rev) )
                     build_async.log :debug, "component's distribution is already pulled before as #{record[:distribution]}"
                     archive_name_with_revision = record[:distribution]
                     _pull_distribution_into_pinto_repo archive_name_with_revision # re-pulling distribution again, just in case 
                 else
    
                     archive_name = _create_distribution_archive cmp
                     build_async.log :debug, "component's distribution archive #{archive_name} has been successfully created"
    
                     archive_name_with_revision = _add_distribution_to_pinto_repo cmp, archive_name, pinto_distro_rev
    
                     # paranoid check:
    		         _distribution_in_pinto_repo! archive_name_with_revision
                     build_async.log :debug, "component's distribution archive #{archive_name_with_revision} has been successfully added to pinto repository"
    
                     if cmp.main?
                         final_distribution_archive = archive_name_with_revision
          		         final_distribution_revision = pinto_distro_rev
                         build_async.log :debug, "application main distribution archive : #{final_distribution_archive}"
                         build_async.log :debug, "application main distribution revision : #{final_distribution_revision}"
                     else
                         new_distribution = distributions.new
                         new_distribution.update({ :revision => rev, :url => cmp.url, :distribution => archive_name_with_revision,  :indexed_url => cmp.indexed_url })
                         new_distribution.save!
                     end
    
                 end
    
                 distributions_list << { :archive_name_with_revision => archive_name_with_revision, :revision => rev, :cmp => cmp }
    
    
        end

        distributions_list.each do |item|
            _install_pinto_distribution item[:archive_name_with_revision]
             item[:cmp].update!({ :revision => item[:revision] })    
             item[:cmp].save!
        end

        if final_distribution_archive.nil?
            raise "main component's distribution archive not found!" 
        end


        distribution_archive_local_path = _artefact_final_distribution final_distribution_archive, final_distribution_revision
        build_async.log :debug, "main component's distribution archive has been successfully created and artefactored as #{distribution_archive_local_path}"
        build_async.log :info,  "done building"
    end

      def _execute_command(cmd, raise_ex = true)

        retval = false
    	build_async.log :info, "running command: #{cmd}"

        chunk = ""

        Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|

            i = 0; chunk = []
            while line = stdout_err.gets
                i += 1
                chunk << line
                if chunk.size > 30
                    build_async.log :debug,  ( chunk.join "" )
                    chunk = []
                end
            end

            # write first / last chunk
            unless chunk.empty?
                build_async.log :debug,  ( chunk.join "" )
            end
    
            exit_status = wait_thr.value
            retval = exit_status.success?
            unless exit_status.success?

	        build_async.log :info, "command failed"
                raise "command #{cmd} failed" if raise_ex == true
            end

        end

	    build_async.log :info, "command succeeded"
        retval

    end


    def _create_distribution_archive cmp
        cmd = []
        cmd <<  "cd #{project.local_path}/#{build.local_path}/#{cmp.local_path}"
        cmd <<  "rm -rf *.gz && rm -rf MANIFEST"
        cmd <<  _set_perl5lib("#{ENV['HOME']}/lib/perl5")

        if File.exists? "#{project.local_path}/#{build.local_path}/#{cmp.local_path}/Build.PL"
	        cmd <<  "perl Build.PL --quiet 1>/dev/null"
            cmd <<  "./Build realclean && perl Build.PL --quiet 1>/dev/null"
            cmd <<  "./Build manifest --quiet 1>/dev/null"
            cmd <<  "./Build dist --quiet 1>/dev/null"
        else
	        cmd <<  "perl Makefile.PL 1>/dev/null"
            cmd <<  "make realclean && perl Makefile.PL 1>/dev/null"
            cmd <<  "make manifest 1>/dev/null"
            cmd <<  "make dist 1>/dev/null"
        end
        _execute_command(cmd.join(' && '))
        distro_name = `cd #{project.local_path}/#{build.local_path}/#{cmp.local_path} && ls *.gz`.chomp!
    end

    def _distribution_in_pinto_repo! archive_name_with_revision
        cmd =  "export PINTO_LOCKFILE_TIMEOUT=10000 && pinto -r #{settings.pinto_repo_root} list -s #{_stack} -D #{archive_name_with_revision} --no-color"
        _execute_command(cmd)
    end

    def _pull_distribution_into_pinto_repo archive_name_with_revision
        cmd =  "export PINTO_LOCKFILE_TIMEOUT=10000 && pinto -r #{settings.pinto_repo_root} pull -s #{_stack} PINTO/#{archive_name_with_revision} #{settings.skip_missing_prerequisites_as_pinto_param} --no-color"
        _execute_command(cmd)
    end

    def _add_distribution_to_pinto_repo cmp, archive_name, rev
        archive_name_with_revision = archive_name.sub('.tar.gz', ".#{rev}.tar.gz")
        cmd = []
        cmd <<  "cd #{project.local_path}/#{build.local_path}/#{cmp.local_path}"
        cmd << "mv #{archive_name} #{archive_name_with_revision}"
        cmd <<  "export PINTO_LOCKFILE_TIMEOUT=10000 &&  pinto -r #{settings.pinto_repo_root} add -s #{_stack} #{settings.skip_missing_prerequisites_as_pinto_param} --author PINTO -v --use-default-message --no-color --recurse #{archive_name_with_revision}"
        _execute_command(cmd.join(' && '))
        archive_name_with_revision
    end

    def _install_pinto_distribution archive_name
        _execute_command("#{_set_perl5lib} && #{modulebuildrc} export PINTO_LOCKFILE_TIMEOUT=10000 &&  pinto -r #{settings.pinto_repo_root} install -s #{_stack} -v --no-color #{cpanm_flags} -l #{project.local_path}/#{build.local_path}/cpanlib  PINTO/#{archive_name}") 
    end

    def _artefact_final_distribution final_distribution_archive, revision

	    timestamp = Time.now.strftime '%Y-%m-%d_%H-%M-%S'

	    original_distribution_archive_dir = final_distribution_archive.sub(".#{revision}.tar.gz",'')

	    final_distribution_archive_with_timestamp = final_distribution_archive.sub('.tar.gz',"-#{timestamp}.tar.gz")
	    final_distribution_archive_dir_with_timestamp = final_distribution_archive.sub('.tar.gz',"-#{timestamp}")
	
        cmd = []
        cmd <<  "cd #{project.local_path}/#{build.local_path}/artefacts/"
        cmd << "cp #{settings.pinto_repo_root}/authors/id/P/PI/PINTO/#{final_distribution_archive} ."
        cmd << "gunzip  #{final_distribution_archive}"
        cmd << "tar -xf #{final_distribution_archive.sub('.gz','')}"
    	cmd << "mv #{original_distribution_archive_dir} #{final_distribution_archive_dir_with_timestamp}"
        cmd << "cd #{final_distribution_archive_dir_with_timestamp}"
        cmd << "cp -r #{project.local_path}/#{build.local_path}/cpanlib ."
        cmd << "cd ../"
        cmd << "tar -czf #{final_distribution_archive_with_timestamp} #{final_distribution_archive_dir_with_timestamp}"
        _execute_command(cmd.join(' && '))

        build.update({ :distribution_name => final_distribution_archive_with_timestamp })
        build.save

        "#{project.local_path}/#{build.local_path}/artefacts/#{final_distribution_archive_with_timestamp}"        
    end


    def _initialize

         FileUtils.mkdir_p "#{project.local_path}/#{build.local_path}/cpanlib/"
         FileUtils.mkdir_p "#{project.local_path}/#{build.local_path}/artefacts"

         build_async.log :info,  "project's local path has been successfully created: #{project.local_path}"
         build_async.log :info,  "build's local path has been successfully created: #{project.local_path}/#{build.local_path}"

         unless File.exist? "#{settings.pinto_repo_root}/.pinto"
             FileUtils.mkdir_p "#{settings.pinto_repo_root}"
             _execute_command "pinto --root=#{settings.pinto_repo_root} init"
             build_async.log :debug, "pinto repository has been successfully created with root at: #{settings.pinto_repo_root}"
         end

         if build.has_ancestor?
             build_async.log :info, "using ancestor's stack for this build - #{_ancestor_stack}"
            _execute_command "export PINTO_LOCKFILE_TIMEOUT=10000 && pinto --root=#{settings.pinto_repo_root} copy #{_ancestor_stack} #{_stack} --no-color"
         else   
            if File.exist? "#{settings.pinto_repo_root}/stacks/#{project.id}"
                build_async.log :info, "using predefined stack for this build - #{project.id}"
                _execute_command "export PINTO_LOCKFILE_TIMEOUT=10000 && pinto --root=#{settings.pinto_repo_root} copy #{project.id} #{_stack} --no-color"
            else
                build_async.log :info, "neither ancestor's nor predefined stacks available for this build, creating very first one -  #{_stack}"
                _execute_command "export PINTO_LOCKFILE_TIMEOUT=10000 && pinto --root=#{settings.pinto_repo_root} new #{_stack} --no-color"
            end
         end

         build.update({ :has_stack => true })
         build.save!
         sleep 5 # wait for awhile, because `pinto copy` command does not create stack immediately
    end

    def _ancestor_stack
        ancestor = build.ancestor
	    "#{project.id}-#{ancestor.id}"
    end

    def _stack
	    "#{project.id}-#{build.id}"
    end
		
    def _set_perl5lib path = nil

        inc = []
        inc << path unless path.nil?
        inc << "#{project.local_path}/#{build.local_path}/cpanlib/lib/perl5"

        if ! (settings.perl5lib.nil?) and ! (settings.perl5lib.empty?)
            settings.perl5lib.split(/\s+/).each do |p|
                inc << p
            end
        end
        "export PERL5LIB=#{inc.join(':')}"
    end

    def modulebuildrc
        if project.verbose?
            "export MODULEBUILDRC=#{settings.modulebuildrc} && "
        else
            ''
        end
    end

    def cpanm_flags
        if project.verbose?
            '-o v'
        else
            ''
        end
    end
end


