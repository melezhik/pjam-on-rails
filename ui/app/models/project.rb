class Project < ActiveRecord::Base

    has_many  :sources
    has_many :builds

    validates :title, presence: true , length: { minimum: 2 }

    def sources_ordered
        sources.sort { |x, y| ( y[:sn] <=> x[:sn] ) || (y[:id] <=> x[:id])  }
    end

    def sources_enabled
        sources_ordered.select { |s| s[:state] == 't'  }
    end

    def last_build
        builds.last
    end

    def last_successfull_build
        builds.select {|b| b.state == 'succeeded' and ! b.distribution_name.nil?  }.last
    end

    def has_last_successfull_build?
         last_successfull_build.nil? == false
    end

    def has_distribution_source?
        begin
            distribution_source
            true
        rescue ActiveRecord::RecordNotFound => ex
            false
        end
    end

    def distribution_source
        sources.find distribution_source_id
    end

    def distribution_url
        url = if has_distribution_source? == true
            distribution_source[:url]
        else
            nil
        end
    end

    def local_path
        "#{Rails.public_path}/projects/#{id}"
    end

    def pinto_repo_root
        "#{Rails.public_path}/repo"
    end

end

