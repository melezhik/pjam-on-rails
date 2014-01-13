class Project < ActiveRecord::Base
    has_many  :sources
    validates :title, presence: true , length: { minimum: 2 }
end
