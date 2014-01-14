class Project < ActiveRecord::Base
    has_many  :sources
    validates :title, presence: true , length: { minimum: 2 }

    def sources_ordered
        sources.sort { |x, y| ( y[:sn] <=> x[:sn] ) || (y[:id] <=> x[:id])  }
    end
end
