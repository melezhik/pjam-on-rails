class AddNotifyColumnToProject < ActiveRecord::Migration
  def change
    add_column :projects, :notify, :boolean, :default => true
    add_column :projects, :recipients, :text
  end
end
