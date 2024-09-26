class AddIndexToFollows < ActiveRecord::Migration[6.1]
  def change
    add_index :follows, [:user_id, :follow_user_id], unique: true
  end
end
