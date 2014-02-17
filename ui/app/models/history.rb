class History < ActiveRecord::Base
  belongs_to :project
  validates :action, presence: true
end
