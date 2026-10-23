# Syncs DIBBS daily RFQ files into the rfqs table.
#
# Files are imported oldest first so the newest copy of a line wins; posted_on keeps the
# earliest file date a line was seen in, even when files are re-imported.
module Dibbs
  class Importer
    # Data columns only take the incoming value when its file is at least as new as the stored one,
    # so the result doesn't depend on import order (e.g. a missed day fetched later).
    DATA_COLUMNS = %w[nsn fsc item_name quantity unit return_by buyer amsc item_type set_aside set_aside_pct updated_at]
    UPDATE_SQL = [
      *DATA_COLUMNS.map { "#{_1} = CASE WHEN excluded.last_seen_on >= rfqs.last_seen_on THEN excluded.#{_1} ELSE rfqs.#{_1} END" },
      "posted_on = MIN(rfqs.posted_on, excluded.posted_on)",
      "last_seen_on = MAX(rfqs.last_seen_on, excluded.last_seen_on)"
    ].join(", ")

    def initialize(client: Client.new, log: Rails.logger)
      @client = client
      @log = log
    end

    # Fetches days not imported yet plus the newest listed day again (it may be re-posted).
    def sync(full: false)
      SyncRun.track do |run|
        files = @client.recent_files
        raise Client::Error, "No RFQ files listed" if files.empty?

        done = ImportedFile.pluck(:file_date).to_set
        todo = full ? files : files.select { !done.include?(_1[:date]) || _1 == files.last }

        todo.each do |f|
          rows = import(@client.get(f[:url]), date: f[:date], url: f[:url])
          run.files_count += 1
          run.rows_count += rows
        end
        run.message = "#{todo.size} of #{files.size} listed files fetched (#{files.first[:date]} .. #{files.last[:date]})"
      end
    end

    # Imports one local file; the date comes from its inYYMMDD name.
    def import_path(path)
      date = Date.strptime(File.basename(path)[/in(\d{6})/i, 1].to_s, "%y%m%d")
      SyncRun.track do |run|
        run.rows_count = import(File.read(path, encoding: "ISO-8859-1:UTF-8"), date: date, url: path)
        run.files_count = 1
        run.message = "imported #{path}"
      end
    rescue Date::Error
      raise ArgumentError, "File name must contain inYYMMDD: #{path}"
    end

    # Upserts one file's records in one transaction; returns the number of rows in the file.
    def import(body, date:, url:)
      records, rejected = RfqFile.parse(body)
      now = Time.current
      rows = records.map { _1.merge(posted_on: date, last_seen_on: date, created_at: now, updated_at: now) }

      Rfq.transaction do
        rows.each_slice(1000) do |slice|
          Rfq.upsert_all(slice, unique_by: %i[solicitation purchase_request],
                                on_duplicate: Arel.sql(UPDATE_SQL), record_timestamps: false)
        end
        ImportedFile.upsert({ file_date: date, url: url, rows_count: rows.size, imported_at: now }, unique_by: :file_date)
      end
      @log.info "[dibbs] #{date}: #{rows.size} rows, #{rejected} rejected"
      rows.size
    end
  end
end
