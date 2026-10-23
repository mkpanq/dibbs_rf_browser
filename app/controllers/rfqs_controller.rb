class RfqsController < ApplicationController
  PER_PAGE = 100
  # URL key => column. The whole filtered result is ordered in SQL before paging.
  SORT_COLUMNS = {
    "solicitation" => :solicitation, "nsn" => :nsn, "item" => :item_name, "quantity" => :quantity,
    "set_aside" => :set_aside, "posted" => :posted_on, "closes" => :return_by, "buyer" => :buyer
  }.freeze
  # First click on a header: biggest / newest first; everything else A→Z, soonest first.
  DESC_FIRST = %w[quantity posted].freeze
  CLOSING_WITHIN = [ 3, 7, 14, 30 ].freeze

  helper_method :default_dir

  def index
    @today = Date.current
    @sort = SORT_COLUMNS.key?(params[:sort]) ? params[:sort] : "closes"
    @dir = %w[asc desc].include?(params[:dir]) ? params[:dir] : default_dir(@sort)
    @fscs = Array(params[:fsc]).join(",").scan(/\d{4}/).uniq # fsc[]=5305 or fsc=5305,5310
    @set_asides = Array(params[:set_aside]) & Dibbs::RfqFile::SET_ASIDES.keys
    @closing_within = params[:closing_within].to_i if CLOSING_WITHIN.include?(params[:closing_within].to_i)
    @min_qty = params[:min_qty].to_i if params[:min_qty].to_i.positive?
    @include_closed = params[:include_closed] == "1"

    scope = Rfq.search(params[:q])
    scope = scope.open_on(@today) unless @include_closed
    scope = scope.where(return_by: ..@today + @closing_within) if @closing_within
    scope = scope.where(fsc: @fscs) if @fscs.any?
    scope = scope.where(set_aside: @set_asides) if @set_asides.any?
    scope = scope.where(quantity: @min_qty..) if @min_qty

    @total = scope.count
    @last_page = [ (@total / PER_PAGE.to_f).ceil, 1 ].max
    @page = params[:page].to_i.clamp(1, @last_page)
    @rfqs = scope.order(SORT_COLUMNS[@sort] => @dir).order(:return_by, :id)
                 .offset((@page - 1) * PER_PAGE).limit(PER_PAGE)

    @data_as_of = ImportedFile.maximum(:file_date)
    @sync = SyncRun.finished.last
    @top_fscs = Rfq.open_on(@today).where.not(fsc: nil).group(:fsc).order(count_all: :desc).limit(8).count
    @filtered = params.slice(:q, :fsc, :set_aside, :closing_within, :min_qty, :include_closed).values.any?(&:present?)
  end

  private

  def default_dir(sort)
    DESC_FIRST.include?(sort) ? "desc" : "asc"
  end
end
