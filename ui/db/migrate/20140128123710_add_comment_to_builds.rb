class AddCommentToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :comment, :text
  end
end
