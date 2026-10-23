namespace :dibbs do
  desc "Download the newest DIBBS RFQ file (in memory) and print a summary"
  task fetch_latest: :environment do
    client = Dibbs::Client.new
    files = client.recent_files
    newest = files.last or abort "No RFQ files listed"
    body = client.get(newest[:url])
    lines = body.lines

    puts "#{files.size} files listed (#{files.first[:date]} .. #{newest[:date]})"
    puts "#{newest[:url]}: #{body.bytesize} bytes, #{lines.size} lines"
    puts lines.first
  end

  desc "Import DIBBS RFQs: new days + newest day again. FULL=1 refetches all listed days, FILE=path imports one local file"
  task import: :environment do
    importer = Dibbs::Importer.new(log: ActiveSupport::Logger.new($stdout))
    run = ENV["FILE"].present? ? importer.import_path(ENV["FILE"]) : importer.sync(full: ENV["FULL"].present?)
    puts "#{run.status}: #{run.message}; #{run.files_count} files, #{run.rows_count} rows; #{Rfq.count} RFQs in DB"
  end

  desc "Run dibbs:import only when the database has no RFQs yet (used by bin/setup)"
  task import_if_empty: :environment do
    if Rfq.exists?
      puts "#{Rfq.count} RFQs already imported, skipping"
    else
      Rake::Task["dibbs:import"].invoke
    end
  end
end
