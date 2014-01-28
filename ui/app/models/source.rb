class Source < ActiveRecord::Base
    belongs_to :project

    def local_path
        "sources/#{id}"
    end

    def enabled?
        state == true
    end
end
