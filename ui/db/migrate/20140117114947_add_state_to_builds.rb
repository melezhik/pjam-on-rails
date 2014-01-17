class AddStateToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :log, :string
  end
end
