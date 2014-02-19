class AddParentIdToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :parent_id, :integer
  end
end
