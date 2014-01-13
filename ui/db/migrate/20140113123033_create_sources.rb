class CreateSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.string :url
      t.text :scm_type
      t.references :project, index: true
      t.timestamps
    end
  end
end
