class AddLastRevToSources < ActiveRecord::Migration
  def change
    add_column :sources, :last_rev, :string
  end
end
