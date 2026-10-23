class Rfq < ApplicationRecord
  scope :open_on, ->(date) { where(return_by: date..) }

  # Every word must match: solicitation prefix, any part of the NSN (dashes ignored, so a bare
  # NIIN works), or the item name (also in singular form: "valves" finds VALVE).
  def self.search(query)
    query.to_s.upcase.split(/[\s,]+/).reject(&:blank?).inject(all) do |scope, word|
      code = sanitize_sql_like(word.delete("-"))
      nouns = [ word.singularize, word.chomp("S") ].uniq.map { "%#{sanitize_sql_like(_1)}%" }
      scope.where(
        "solicitation LIKE :prefix ESCAPE '\\' OR nsn LIKE :code ESCAPE '\\' " \
        "OR item_name LIKE :noun1 ESCAPE '\\' OR item_name LIKE :noun2 ESCAPE '\\'",
        prefix: "#{code}%", code: "%#{code}%", noun1: nouns.first, noun2: nouns.last
      )
    end
  end

  def set_aside_label
    Dibbs::RfqFile::SET_ASIDES.fetch(set_aside, set_aside) unless set_aside.blank? || set_aside == "N"
  end
end
