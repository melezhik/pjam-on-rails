class ChangeDefaultForSourcesSn < ActiveRecord::Migration
  def change
    change_column :sources, :sn, :integer, :default => 0
  end
end
