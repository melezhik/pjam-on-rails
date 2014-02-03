class Source < ActiveRecord::Base

    belongs_to :project
    validates :url, presence: true

    def local_path
        "sources/#{id}"
    end

    def enabled?
        state == true
    end
end
