class AddIconToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :icon, :string
  end
end
