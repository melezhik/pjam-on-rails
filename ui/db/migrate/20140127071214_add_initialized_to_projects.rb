class AddInitializedToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :initialized, :bool, :default => false
  end
end
