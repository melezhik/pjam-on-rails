class AddNotifyColumnToSettings < ActiveRecord::Migration
  def change
    add_column :settings, :jabber_login, :string
    add_column :settings, :jabber_password, :string
  end
end
