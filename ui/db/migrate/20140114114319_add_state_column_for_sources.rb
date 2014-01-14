class AddStateColumnForSources < ActiveRecord::Migration
  def change
    add_column :sources, :state, :bool, :default => true
  end
end
