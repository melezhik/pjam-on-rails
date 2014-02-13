class ChangeIsDistributionUrlDefValue < ActiveRecord::Migration
  def change
        change_column :snapshots, :is_distribution_url, :boolean, :default => false
  end
end
