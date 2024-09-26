class CreateContents < ActiveRecord::Migration[6.1]
  def change
    create_table :contents do |t|
      t.integer :user_id
      t.string :content
      t.string :picture
      t.string :position
      t.integer :likenumber
      t.timestamps
    end
  end
end
