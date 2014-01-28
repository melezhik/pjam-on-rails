class AddLockedToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :locked, :boolean, :default => false
  end
end
