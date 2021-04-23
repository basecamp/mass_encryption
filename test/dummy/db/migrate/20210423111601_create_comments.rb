class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments do |t|
      t.timestamps
    end
  end
end
