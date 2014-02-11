class Distribution < ActiveRecord::Base
    validates :indexed_url, presence: true
    validates :url, presence: true
end
