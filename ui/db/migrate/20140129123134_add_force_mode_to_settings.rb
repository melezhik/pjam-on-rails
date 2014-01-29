class AddForceModeToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :force_mode, :boolean, :default => false 
  end
end
