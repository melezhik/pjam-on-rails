class AddGitFolderToSnapshots < ActiveRecord::Migration
  def change
    add_column :snapshots, :git_folder, :string
  end
end
