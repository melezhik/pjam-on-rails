class AddVerboseToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :verbose, :boolean, :default => false
  end
end
