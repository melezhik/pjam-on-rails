class AddIsDistributionUrlToSnapshots < ActiveRecord::Migration
  def change
    add_column :snapshots, :is_distribution_url, :boolean, :default => false
  end
end
