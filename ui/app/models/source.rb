class Source < ActiveRecord::Base

    belongs_to :project
    validates :url, presence: true, length: { minimum: 2 }

    def local_path
        "sources/#{id}"
    end

    def enabled?
        state == true
    end
end
