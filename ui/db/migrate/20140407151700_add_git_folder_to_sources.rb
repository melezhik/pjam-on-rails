class AddGitFolderToSources < ActiveRecord::Migration
  def change
    add_column :sources, :git_folder, :string
  end
end
