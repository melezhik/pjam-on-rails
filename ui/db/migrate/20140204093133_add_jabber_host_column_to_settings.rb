class AddJabberHostColumnToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :jabber_host, :string
  end
end
