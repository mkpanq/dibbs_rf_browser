class CreateSyncRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :sync_runs do |t|
      t.string :status, null: false, default: "running"
      t.text :message
      t.integer :files_count, null: false, default: 0
      t.integer :rows_count, null: false, default: 0
      t.datetime :started_at, null: false
      t.datetime :finished_at
    end
  end
end
