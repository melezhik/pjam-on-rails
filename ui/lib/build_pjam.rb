require 'fileutils'
require 'crack'
require 'open3'

class BuildPjam < Struct.new( :build_async, :project, :build )


    @@FORCE_MODE = false

    def self.set_force_mode mode
        @@FORCE_MODE = mode
    end

    def run

         FileUtils.mkdir_p "#{project.local_path}/repo"
         FileUtils.mkdir_p "#{project.local_path}/#{build.local_path}"
         build_async.log :info,  "project local path has been successfully created: #{build.local_path}"
         build_async.log :info,  "build local path has been successfully created: #{project.local_path}/#{build.local_path}"
         unless File.exist? "#{project.local_path}/repo/.pinto"
             _execute_command "pinto --root=#{project.local_path}/repo/ init"
             build_async.log :debug, "pinto repository has been successfully initialized"
         end


        project.sources_enabled.each  do |s|

             build_async.log :info,  "processing source: #{s[:url]}"
             FileUtils.rm_rf "#{project.local_path}/#{build.local_path}/#{s.local_path}"
             FileUtils.mkdir_p "#{project.local_path}/#{build.local_path}/#{s.local_path}"       
             build_async.log :debug,  "source local path: #{project.local_path}/#{build.local_path}/#{s.local_path} has been successfully created"
             _execute_command "svn info #{s[:url]}" # check if repository available
             xml = `svn --xml info #{s[:url]}`.force_encoding("UTF-8")
             repo_info = Crack::XML.parse xml
             rev = repo_info["info"]["entry"]["commit"]["revision"]
             build_async.log :debug,  "last revision: #{rev}"
             if (@@FORCE_MODE == false and  ! s.last_rev.nil?) and s.last_rev == rev
                 build_async.log :debug, "this revison is already processed, nothing to do here"
             else
                 if (! s.last_rev.nil? and ! rev.nil? )
                    build_async.log :debug,  "changes for #{s.url} between #{rev} and #{s.last_rev}"
                    _execute_command "svn diff #{s.url} -r #{s.last_rev}:#{rev}"
                 end

                 _execute_command "svn co #{s.url} #{project.local_path}/#{build.local_path}/#{s.local_path} -q"
                 build_async.log :debug, "source has been successfully checked out"
                 distro_name = _create_distribution project, build, s
                 build_async.log :debug, "distribution archive #{distro_name} has been successfully created"
                 s.update({ :last_rev => rev })    
                 s.save
             end

        end
        
    end

      def _execute_command(cmd)

        Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
            while line = stdout_err.gets
                build_async.log :debug, line
            end
            exit_status = wait_thr.value
            unless exit_status.success?
              raise "command #{cmd} failed"
           end
        end

    end


    def _create_distribution project, build, source
        cmd = []
        cmd <<  "cd #{project.local_path}/#{build.local_path}/#{source.local_path}"
        cmd <<  "rm -rf *.gz && rm -rf MANIFEST"
        cmd <<  "perl Build.PL --quiet 1>/dev/null 2>module_build.err.log"
        cmd <<  "./Build realclean && perl Build.PL --quiet 1>/dev/null 2>module_build.err.log"
        cmd <<  "./Build manifest --quiet 2>/dev/null 1>/dev/null"
        cmd <<  "./Build dist --quiet 1>/dev/null"
        _execute_command(cmd.join(' && '))
        distro_name = `cd #{project.local_path}/#{build.local_path}/#{source.local_path} && ls *.gz`.chomp!
    end

end


