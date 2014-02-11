require 'uri'
class Source < ActiveRecord::Base

    belongs_to :project
    validates :url, presence: true

    def local_path
        "sources/#{id}"
    end

    def enabled?
        state == true
    end

    def _indexed_url
        URI.split(url)[2] + (URI.split(url)[5]).sub(/\/$/,"")
    end

end
