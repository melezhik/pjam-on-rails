class AddVerboseToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :verbose, :boolean, :default => false
    remove_column :settings, :verbose
  end
end
