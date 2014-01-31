class AddReleasedToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :released, :boolean, :default => false
  end
end
