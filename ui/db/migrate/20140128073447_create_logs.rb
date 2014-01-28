class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.text :chunk
      t.references :build, index: true

      t.timestamps
    end
  end
end
