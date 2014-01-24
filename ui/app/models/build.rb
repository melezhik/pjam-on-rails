class Build < ActiveRecord::Base
    belongs_to :project
    
    def local_path
        "builds/#{id}"
    end

end

