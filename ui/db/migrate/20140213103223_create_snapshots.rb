class CreateSnapshots < ActiveRecord::Migration
  def change
    create_table :snapshots do |t|
      t.string :indexed_url
      t.references :build, index: true

      t.timestamps
    end
  end
end
