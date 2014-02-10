require 'fileutils'
require 'crack'
require 'open3'

class BuildPjam < Struct.new( :build_async, :project, :last_build, :build, :distributions, :settings  )

    def run

         raise "distribution source should be set for this project" if project.has_distribution_source? == false
         build_async.log :debug,  "settings.force_mode: #{settings[:force_mode]}"
         build_async.log :debug,  "settings.pinto_repo_root: #{settings.pinto_repo_root}"
         build_async.log :debug,  "settings.skip_missing_prerequisites: #{settings.skip_missing_prerequisites || 'not set'}"

         _initialize

        distributions_list = []
        distribution_archive = []
        project.sources_enabled.each  do |s|

             build_async.log :info,  "processing source: #{s[:url]}"

             FileUtils.rm_rf "#{project.local_path}/#{build.local_path}/#{s.local_path}"
             FileUtils.mkdir_p "#{project.local_path}/#{build.local_path}/#{s.local_path}"       

             build_async.log :debug,  "source local path: #{project.local_path}/#{build.local_path}/#{s.local_path} has been successfully created"
             _execute_command "svn info #{s[:url]}" # check if repository available
             xml = `svn --xml info #{s[:url]}`.force_encoding("UTF-8")
             repo_info = Crack::XML.parse xml
             rev = repo_info["info"]["entry"]["commit"]["revision"]
             build_async.log :debug,  "last revision extracted from repoisitory: #{rev}"

             if (! s.last_rev.nil? and ! rev.nil? )
                build_async.log :debug,  "changes for #{s.url} between #{rev} and #{s.last_rev}"
                _execute_command "svn log #{s.url} -r #{s.last_rev}:#{rev}"
                _execute_command "svn diff #{s.url} -r #{s.last_rev}:#{rev}"
                s.update({ :last_rev => rev })    
                s.save!
             end

        	 pinto_distro_rev =  "#{rev}-#{build.id}"
             _execute_command "svn co #{s.url} #{project.local_path}/#{build.local_path}/#{s.local_path} -q"
             build_async.log :debug, "source has been successfully checked out"
            
             if ! (project.distribution_source.url == s.url) and record = distributions.find_by(url: s[:url], revision: rev)
                 build_async.log :debug, "distribution was already pulled before as #{record[:distribution]}"
                 archive_name_with_revision = record[:distribution]
                 _pull_distribution_into_pinto_repo archive_name_with_revision # re-pulling distribution again, just in case 
             else

                 archive_name = _create_distribution_archive s
                 build_async.log :debug, "distribution archive #{archive_name} has been successfully created"

                 archive_name_with_revision = _add_distribution_to_pinto_repo s, archive_name, pinto_distro_rev
                 # paranoid check:
    		     _distribution_in_pinto_repo! archive_name_with_revision
                 build_async.log :debug, "distribution archive #{archive_name_with_revision} has been successfully added to pinto repository"

                 if project.distribution_source.url == s.url
                     distribution_archive = [ archive_name_with_revision, archive_name ] 
                 else
                     new_distribution = distributions.new
                     new_distribution.update({ :revision => rev, :url => s[:url], :distribution => archive_name_with_revision })
                     new_distribution.save!
                 end

             end

             distributions_list << archive_name_with_revision

        end

        distributions_list.each do |archive_name|
            _install_pinto_distribution archive_name 
        end

        if distribution_archive.empty?
            raise "distribution archive not found!" 
        end


        distribution_archive_local_path = _create_final_distribution distribution_archive
        build_async.log :debug, "final distribution archive has been successfully created and artefactored as #{distribution_archive_local_path}"
        build.update({ :distribution_name => distribution_archive[1] })
        build.save

    end

      def _execute_command(cmd, raise_ex = true)
        retval = false
    	build_async.log :info, "running command: #{cmd}"
        Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
            while line = stdout_err.gets
                build_async.log :debug, line
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


    def _create_distribution_archive source
        cmd = []
        cmd <<  "cd #{project.local_path}/#{build.local_path}/#{source.local_path}"
        cmd <<  "rm -rf *.gz && rm -rf MANIFEST"
        cmd <<  _set_perl5lib
	    cmd <<  "perl Build.PL --quiet 1>/dev/null"
        cmd <<  "./Build realclean && perl Build.PL --quiet 1>/dev/null"
        cmd <<  "./Build manifest --quiet 1>/dev/null"
        cmd <<  "./Build dist --quiet 1>/dev/null"
        _execute_command(cmd.join(' && '))
        distro_name = `cd #{project.local_path}/#{build.local_path}/#{source.local_path} && ls *.gz`.chomp!
    end

    def _distribution_in_pinto_repo! archive_name_with_revision
        cmd =  "pinto -r #{settings.pinto_repo_root} list -s #{_stack} -D #{archive_name_with_revision} --no-color"
        _execute_command(cmd)
    end

    def _pull_distribution_into_pinto_repo archive_name_with_revision
        cmd =  "pinto -r #{settings.pinto_repo_root} pull -s #{_stack} PINTO/#{archive_name_with_revision} --no-color"
        _execute_command(cmd)
    end

    def _remove_distribution_from_pinto_repo archive_name, rev
        archive_name_with_revision = archive_name.sub('.tar.gz', ".#{rev}.tar.gz")
        cmd =  "pinto -r #{settings.pinto_repo_root} delete PINTO/#{archive_name_with_revision} --no-color"
        _execute_command(cmd, true)
    end

    def _add_distribution_to_pinto_repo source, archive_name, rev
        archive_name_with_revision = archive_name.sub('.tar.gz', ".#{rev}.tar.gz")
        cmd = []
        cmd <<  "cd #{project.local_path}/#{build.local_path}/#{source.local_path}"
        cmd << "mv #{archive_name} #{archive_name_with_revision}"
        cmd <<  "pinto -r #{settings.pinto_repo_root} add -s #{_stack} #{settings.skip_missing_prerequisites_as_pinto_param} --author PINTO -v --use-default-message --no-color --recurse #{archive_name_with_revision}"
        _execute_command(cmd.join(' && '))
        archive_name_with_revision
    end

    def _install_pinto_distribution archive_name
        _execute_command("#{_set_perl5lib} && pinto -r #{settings.pinto_repo_root} install -s #{_stack} -v --no-color -o 'v' -l #{project.local_path}/cpanlib  PINTO/#{archive_name}") 
    end

    def _create_final_distribution distribution_archive
        cmd = []
        cmd <<  "cd #{project.local_path}/#{build.local_path}/artefacts/"
        cmd << "cp #{settings.pinto_repo_root}/authors/id/P/PI/PINTO/#{distribution_archive[0]} ."
        cmd << "gunzip  #{distribution_archive[0]}"
        cmd << "tar -xf #{distribution_archive[0].sub('.gz','')}"
        cmd << "cd #{distribution_archive[1].sub('.tar.gz','')}"
        cmd << "cp -r #{project.local_path}/cpanlib ."
        cmd << "cd ../"
        cmd << "tar -czf #{distribution_archive[1]}  #{distribution_archive[1].sub('.tar.gz','')}"
        _execute_command(cmd.join(' && '))
        "#{project.local_path}/#{build.local_path}/artefacts/#{distribution_archive[1]}"        
    end


    def _initialize

         FileUtils.mkdir_p "#{project.local_path}/repo"
         FileUtils.mkdir_p "#{project.local_path}/#{build.local_path}/artefacts"

         build_async.log :info,  "project local path has been successfully created: #{project.local_path}"
         build_async.log :info,  "build local path has been successfully created: #{project.local_path}/#{build.local_path}"

         unless File.exist? "#{settings.pinto_repo_root}/.pinto"
             _execute_command "pinto --root=#{settings.pinto_repo_root} init"
             build_async.log :debug, "pinto repository has been successfully created with root at: #{settings.pinto_repo_root}"
         end

         if last_build.nil?
            _execute_command "pinto --root=#{settings.pinto_repo_root} new #{_stack} --no-color"
         else   
            _execute_command "pinto --root=#{settings.pinto_repo_root} copy #{_last_stack} #{_stack} --no-color"
         end

         sleep 5 # to privent race conditions ... because of pinto copy command does not create stack immediately
    end

    def _last_stack
	"#{project.id}-#{last_build.id}"
    end

    def _stack
	"#{project.id}-#{build.id}"
    end
		
    def _set_perl5lib
        if settings.perl5lib.nil? or settings.perl5lib.empty?
            "export PERL5LIB=#{project.local_path}/cpanlib/lib/perl5"
        else
            "export PERL5LIB=#{project.local_path}/cpanlib/lib/perl5:" +  ( settings.perl5lib.split(/\s+/).join ':' )
        end
    end

end


