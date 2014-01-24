class AddDistributionNameToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :distribution_name, :string
  end
end
