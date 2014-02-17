class CreateHistories < ActiveRecord::Migration
  def change
    create_table :histories do |t|
      t.string :commiter
      t.string :action
      t.references :project, index: true

      t.timestamps
    end
  end
end
