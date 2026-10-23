module RfqsHelper
  RFQ_URL = "https://www.dibbs.bsm.dla.mil/rfq/rfqrec.aspx?sn=%s"

  def rfq_link(rfq)
    link_to rfq.solicitation, format(RFQ_URL, ERB::Util.url_encode(rfq.solicitation)), target: "_blank", rel: "noopener"
  end

  # 8455012713097 -> 8455-01-271-3097; part numbers and local stock numbers are shown as is
  def format_nsn(nsn)
    nsn.match?(/\A\d{13}\z/) ? nsn.sub(/\A(\d{4})(\d{2})(\d{3})(\d{4})\z/, '\1-\2-\3-\4') : nsn
  end

  def short_date(date)
    date.year == @today.year ? date.strftime("%b %-d") : date.strftime("%b %-d, %Y")
  end

  # "in 5 d" / "today" / "closed"; red when 3 days or less
  def closes_in(date)
    days = (date - @today).to_i
    return tag.span("closed", class: "muted") if days.negative?
    tag.span(days.zero? ? "today" : "in #{days} d", class: ("soon" if days <= 3))
  end

  def set_aside_tag(rfq)
    return tag.span("—", class: "muted") unless (label = rfq.set_aside_label)
    pct = " #{rfq.set_aside_pct}%" if rfq.set_aside_pct.to_i.positive?
    tag.span("#{label}#{pct}", class: "tag")
  end

  # The file cuts item names at 21 chars; mark those so nobody mistakes them for the full name.
  def item_name(rfq)
    return rfq.item_name if rfq.item_name.to_s.length < Dibbs::RfqFile::ITEM_NAME_LENGTH
    tag.span("#{rfq.item_name}…", title: "Cut at 21 characters by the DIBBS file. Full name on the RFQ page.")
  end

  # Column header that sorts the whole result; clicking the active column flips the direction.
  def sort_header(label, key)
    active = @sort == key
    dir = active ? (@dir == "asc" ? "desc" : "asc") : default_dir(key)
    arrow = active ? (@dir == "asc" ? " ▲" : " ▼") : ""
    link_to "#{label}#{arrow}", request.query_parameters.merge(sort: key, dir: dir).except("page"),
            class: [ "sort", ("active" if active) ], "aria-sort": (active ? "#{@dir}ending" : nil),
            data: { turbo_frame: "_top" }
  end
end
