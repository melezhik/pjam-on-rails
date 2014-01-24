class Build < ActiveRecord::Base
    belongs_to :project
    
    def local_path
        "builds/#{id}"
    end


    def download_path

        "/data/#{project.id}/builds/#{id}/artefacts/#{distribution_name}"
    end
end

