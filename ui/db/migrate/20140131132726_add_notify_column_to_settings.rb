class AddNotifyColumnToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :jabber_server, :string
    add_column :settings, :jabber_login, :string
    add_column :settings, :jabber_password, :string
    add_column :settings, :notify, :boolean, :default => true
    add_column :settings, :recipients, :text
  end
end
