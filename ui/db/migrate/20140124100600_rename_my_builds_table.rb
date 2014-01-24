class RenameMyBuildsTable < ActiveRecord::Migration
  def change
    rename_table :my_builds, :builds
  end
end
