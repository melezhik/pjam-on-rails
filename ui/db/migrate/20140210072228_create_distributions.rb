class CreateDistributions < ActiveRecord::Migration
  def change
    create_table :distributions do |t|
      t.string :revision
      t.string :distribution
      t.string :url

      t.timestamps
    end
  end
end
