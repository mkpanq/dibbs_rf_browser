class DibbsSyncJob < ApplicationJob
  queue_as :default

  def perform(full: false)
    Dibbs::Importer.new.sync(full: full)
  end
end
