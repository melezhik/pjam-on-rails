class AddRevisionToSnapshots < ActiveRecord::Migration
  def change
    add_column :snapshots, :revision, :string
  end
end
