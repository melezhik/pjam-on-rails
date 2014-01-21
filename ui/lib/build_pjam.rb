require 'svn'
require 'fileutils'

class BuildPjam


    def run build_async, project

        project.sources_ordered.each  do |s|
             build_async.log :info,  "is going to process source: #{s[:url]}"
             source_local_path = "#{Rails.public_path}/#{project[:id]}#{s[:id]}"
             FileUtils.mkdir_p source_local_path       
             build_async.log :info,  "has created source local path: #{source_local_path}"
             repo = Svn::Repo.open 
             build_async.log :info,  "has checked working copy"
            
        end
        
    end

end

