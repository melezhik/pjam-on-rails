class RenameConfigurationsToSettings < ActiveRecord::Migration
  def change
    drop_table :configurations
  end
end
