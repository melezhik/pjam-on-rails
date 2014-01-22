require 'fileutils'
require 'crack'

class BuildPjam


    def run build_async, project, build

         project_local_path = "#{Rails.public_path}/projects/#{project[:id]}"
         build_local_path = "#{project_local_path}/#{build.id}"
         FileUtils.mkdir_p "#{build_local_path}/repo"
         build_async.log :info,  "build local path has been successfully created: #{build_local_path}"
         unless File.exist? "#{project_local_path}/repo/.pinto"
             cmd = "pinto --root=#{project_local_path}/repo/ init"
             if system(cmd) == true
                 build_async.log :debug, "pinto repository has been successfully initialized"
             else
                 raise "command #{cmd} failed"
             end
         end


        project.sources_ordered.select {|ss| ss.state == 't' }.each  do |s|

             build_async.log :info,  "processing source: #{s[:url]}"
             source_local_path = "#{build_local_path}/sources/#{s[:id]}"
             FileUtils.rm_rf source_local_path
             FileUtils.mkdir_p source_local_path       
             build_async.log :debug,  "source local path: #{source_local_path} has been successfully created"
             xml = `svn --xml info #{s[:url]}`.force_encoding("UTF-8")
             build_async.log :debug,  "repository info: #{xml}"
             repo_info = Crack::XML.parse xml
             rev = repo_info["info"]["entry"]["commit"]["revision"]
             build_async.log :debug,  "last revision: #{rev}"
             if (! s.last_rev.nil?) and s.last_rev == rev
                build_async.log :debug, "this revison is already processed, nothing to do here"
             else
                `svn co #{s.url} #{source_local_path}`
                 build_async.log :debug, "source has been successfully checked out"
             end

             
             s.update({ :last_rev => rev })    
             s.save
        end
        
    end

end

