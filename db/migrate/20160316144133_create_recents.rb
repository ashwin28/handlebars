class CreateRecents < ActiveRecord::Migration
  def change
    create_table :recents do |t|
      t.text :url_string
      t.text :handles
      t.string :url_hash

      t.timestamps null: false
    end
  end
end
