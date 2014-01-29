class CreateConfigurations < ActiveRecord::Migration
  def change
    create_table :configurations do |t|
      t.text :perl5lib
      t.text :skip_missing_prerequisites
      t.text :pinto_upstream_repositories

      t.timestamps
    end
  end
end
