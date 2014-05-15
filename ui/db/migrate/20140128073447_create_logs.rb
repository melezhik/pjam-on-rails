class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.blob :chunk
      t.references :build, index: true

      t.timestamps
    end
  end
end
