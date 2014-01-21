require 'svn'
require 'fileutils'

class BuildPjam


    def run build_async, project

        project.sources_ordered.each  do |s|
             build_async.log :info,  "is going to process source: #{s[:url]}"
             source_local_path = "#{Rails.public_path}/#{project[:id]}/#{s[:id]}"
             FileUtils.mkdir_p source_local_path       
             `svn co #{s[:url]} #{source_local_path}`
             build_async.log :debug,  "has created source local path: #{source_local_path}"
             repo = Svn::Repo.open("#{source_local_path}/.svn/")
             build_async.log :debug,  "has checked out #{s[:url]} into #{source_local_path}"
             lr = repo.revision
             build_async.log :debug,  "last revision: #{lr.props.inspect}"
            
        end
        
    end

end

