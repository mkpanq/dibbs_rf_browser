# Parses a DIBBS daily RFQ file (inYYMMDD.txt): fixed-width, 140 chars per line.
# Layout from https://www.dibbs.bsm.dla.mil/Rfq/RfqFileDefs.aspx
module Dibbs
  class RfqFile
    LAYOUT = [ # field, offset, length
      [ :solicitation,     0, 13 ],
      [ :nsn,             13, 46 ], # NSN or part number
      [ :purchase_request, 59, 13 ],
      [ :return_by,       72,  8 ], # MM/DD/YY
      # 80..98: file name (<solicitation>.pdf), not stored
      [ :quantity,        99,  7 ],
      [ :unit,           106,  2 ],
      [ :item_name,      108, 21 ], # nomenclature, truncated by the file format (ITEM_NAME_LENGTH)
      [ :buyer,          129,  5 ],
      [ :amsc,           134,  1 ],
      [ :item_type,      135,  1 ], # 1 = NSN, 2 = part number
      [ :set_aside,      136,  1 ],
      [ :set_aside_pct,  137,  3 ]
    ].freeze
    LINE_LENGTH = 140
    ITEM_NAME_LENGTH = 21

    SET_ASIDES = {
      "Y" => "Small Business",
      "H" => "HUBZone",
      "R" => "SDVOSB",
      "L" => "WOSB",
      "A" => "8(a)",
      "E" => "EDWOSB",
      "N" => "Unrestricted"
    }.freeze

    # => [records, rejected_line_count]
    def self.parse(body)
      lines = body.each_line.map(&:chomp).reject(&:blank?)
      records = lines.filter_map do |line|
        parse_line(line) if line.length == LINE_LENGTH
      rescue Date::Error
        nil
      end
      [ records, lines.size - records.size ]
    end

    def self.parse_line(line)
      line = line.chomp
      r = LAYOUT.to_h { |name, offset, length| [ name, line[offset, length].to_s.strip ] }
      r[:return_by] = Date.strptime(r[:return_by], "%m/%d/%y")
      r[:quantity] = r[:quantity].to_i
      r[:set_aside_pct] = r[:set_aside_pct].to_i
      # also local stock numbers like 4730LN0035875
      r[:fsc] = r[:item_type] == "1" && r[:nsn].match?(/\A\d{4}/) ? r[:nsn][0, 4] : nil
      r
    end
  end
end
