class AddLatitudeToContents < ActiveRecord::Migration[6.1]
  def change
    add_column :contents, :latitude, :float
  end
end
