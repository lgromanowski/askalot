class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.references :author, null: false
      t.references :group, null: false

      t.string :title, null: false
      t.text   :text, null: false

      t.boolean    :deleted, null: false, default: false
      t.references :deletor, null: true
      t.timestamp  :deleted_at

      t.integer :questions_count, null: false, default: 0

      t.timestamps
    end

    add_index :documents, :group_id
    add_index :documents, :deletor_id

    add_index :documents, :title

    add_index :documents, :questions_count
  end
end
