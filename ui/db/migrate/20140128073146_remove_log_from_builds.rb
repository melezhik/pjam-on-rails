class RemoveLogFromBuilds < ActiveRecord::Migration
  def change
    remove_column :builds, :log, :text
  end
end
