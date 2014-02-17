class AddDistributionToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :distribution_source_id, :integer
  end
end
