class AddIndexToDistributions < ActiveRecord::Migration
  def change
    add_column :distributions, :indexed_url, :string
  end
end
