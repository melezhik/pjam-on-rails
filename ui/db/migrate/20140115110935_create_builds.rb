class CreateBuilds < ActiveRecord::Migration
  def change
    create_table :builds do |t|
      t.integer :state
      t.references :project, index: true

      t.timestamps
    end
  end
end
