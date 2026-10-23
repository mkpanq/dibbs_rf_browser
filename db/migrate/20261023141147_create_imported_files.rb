class CreateImportedFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :imported_files do |t|
      t.date :file_date, null: false, index: { unique: true }
      t.string :url
      t.integer :rows_count, null: false, default: 0
      t.datetime :imported_at, null: false
    end
  end
end
