class ChangeStateColumnForBuilds < ActiveRecord::Migration
  def change
     change_table :builds do |t|
        t.change :state, :string, :default => 'scheduled'
     end
  end
end
