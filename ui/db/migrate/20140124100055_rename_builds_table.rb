class RenameBuildsTable < ActiveRecord::Migration
  def change
    rename_table :builds, :my_builds
  end
end

