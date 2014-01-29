class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.text :perl5lib
      t.text :skip_missing_prerequisites
      t.text :pinto_downsteram_repositories

      t.timestamps
    end
  end
end
