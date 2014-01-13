class AddSnToSources < ActiveRecord::Migration
  def change
    add_column :sources, :sn, :int, :default => 1
  end
end
