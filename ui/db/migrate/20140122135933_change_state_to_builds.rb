class ChangeStateToBuilds < ActiveRecord::Migration
  def change
    change_column_default :builds, :state, 'scheduled'
  end
end
