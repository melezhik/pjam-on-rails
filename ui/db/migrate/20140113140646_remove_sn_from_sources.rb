class RemoveSnFromSources < ActiveRecord::Migration
  def change
    remove_column :sources, :sn, :int
  end
end
