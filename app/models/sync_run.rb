class SyncRun < ApplicationRecord
  scope :finished, -> { where.not(finished_at: nil).order(:finished_at) }

  # Records the run as ok / failed (with the error message); errors are re-raised.
  def self.track
    run = create!(started_at: Time.current)
    yield run
    run.update!(status: "ok", finished_at: Time.current)
    run
  rescue => e
    run&.update!(status: "failed", message: "#{e.class}: #{e.message}", finished_at: Time.current)
    raise
  end

  def failed? = status == "failed"
end
