class AddCityToContents < ActiveRecord::Migration[6.1]
  def change
    add_column :contents, :city, :string
  end
end
