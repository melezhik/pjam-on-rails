class AddStateColumnForSources < ActiveRecord::Migration
  def change
    add_column :sources, :state, :boolean, :default => true
  end
end
