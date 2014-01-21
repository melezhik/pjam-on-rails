require 'fileutils'
require 'crack'

class BuildPjam


    def run build_async, project

        project.sources_ordered.each  do |s|
             build_async.log :info,  "is going to process source: #{s[:url]}"
             source_local_path = "#{Rails.public_path}/projects/#{project[:id]}/#{s[:id]}"
             FileUtils.mkdir_p source_local_path       
             build_async.log :debug,  "has created source local path: #{source_local_path}"
             xml = `svn --xml info #{s[:url]}`.force_encoding("UTF-8")
             build_async.log :debug,  "repository info: #{xml}"
             repo_info = Crack::XML.parse xml
             rev = repo_info["info"]["entry"]["commit"]["revision"]
             build_async.log :debug,  "last revision: #{rev}"
            
        end
        
    end

end

