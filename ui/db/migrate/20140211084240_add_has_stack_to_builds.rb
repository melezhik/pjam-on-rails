class AddHasStackToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :has_stack, :boolean, :default => false
  end
end
