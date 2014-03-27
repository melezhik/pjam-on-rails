class Snapshot < ActiveRecord::Base

    belongs_to :build

    def local_path
        "sources/#{id}"
    end

    def url
        schema + '://' + indexed_url 
    end

    def main?
        is_distribution_url == true        
    end
end
