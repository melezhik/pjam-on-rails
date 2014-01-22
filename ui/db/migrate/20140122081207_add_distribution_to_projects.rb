class AddDistributionToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :distribution, :integer
  end
end
