class AddGitBranchToSnapshots < ActiveRecord::Migration
  def change
    add_column :snapshots, :git_branch, :string
  end
end
