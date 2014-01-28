class AddLevelToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :level, :string
  end
end
