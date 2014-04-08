class AddGitBranchToSources < ActiveRecord::Migration
  def change
    add_column :sources, :git_branch, :string
  end
end
