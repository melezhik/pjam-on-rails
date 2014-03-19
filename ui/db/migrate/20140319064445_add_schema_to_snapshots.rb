class AddSchemaToSnapshots < ActiveRecord::Migration
  def change
    add_column :snapshots, :schema, :string, :default => 'http'
    add_column :snapshots, :scm_type, :string, :default => 'svn'
  end
end
