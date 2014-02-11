class AddIndexToDistributions < ActiveRecord::Migration
  def change
    add_column :distributions, :index, :string
  end
end
