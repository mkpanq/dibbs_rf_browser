require "net/http"

# Fetches pages and files from DIBBS, getting past the DoD consent page on each host.
#
# - One cookie jar per host; redirects are followed by hand so cookies are kept on every hop.
# - Consent is detected from the page body (the `butAgree` button), not from the URL:
#   www redirects to dodwarning.aspx, but dibbs2 serves the consent page with a 200
#   at the file URL itself and answers the consent POST with the file.
# - Don't send a browser-like User-Agent: the F5 WAF rejects a bare "Mozilla/5.0".
module Dibbs
  class Client
    class Error < StandardError; end

    BASE = "https://www.dibbs.bsm.dla.mil"
    RECENT_URL = "#{BASE}/Rfq/RfqDates.aspx?category=recent"
    MAX_HOPS = 10

    def initialize
      @jars = Hash.new { |h, host| h[host] = {} }
    end

    # Daily RFQ files listed on the "Recent RFQs" page, oldest first: [{ date:, url: }]
    def recent_files
      doc = Nokogiri::HTML(get(RECENT_URL))
      doc.css("a[href]").filter_map do |a|
        next unless (m = a["href"].match(/in(\d{6})\.txt\z/i))
        { date: Date.strptime(m[1], "%y%m%d"), url: URI.join(RECENT_URL, a["href"]).to_s }
      end.uniq { _1[:date] }.sort_by { _1[:date] }
    end

    def get(url)
      uri = URI(url)
      form = nil
      consented = false

      MAX_HOPS.times do
        res = request(uri, form)
        form = nil

        if res.is_a?(Net::HTTPRedirection)
          uri = URI.join(uri, res["location"])
          next
        end
        raise Error, "HTTP #{res.code} from #{uri}" unless res.is_a?(Net::HTTPSuccess)

        body = res.body.to_s
        raise Error, "Blocked by DIBBS firewall at #{uri}" if body.include?("<title>Request Rejected</title>")

        if body.include?("butAgree")
          raise Error, "Consent page shown again after accepting at #{uri}" if consented
          uri, form = consent_form(uri, body)
          consented = true
          next
        end

        return body.force_encoding(Encoding::ISO_8859_1).encode(Encoding::UTF_8)
      end
      raise Error, "Too many redirects for #{url}"
    end

    private

    def request(uri, form)
      req = form ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
      req.set_form_data(form) if form
      jar = @jars[uri.host]
      req["Cookie"] = jar.map { |k, v| "#{k}=#{v}" }.join("; ") if jar.any?

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 60) { _1.request(req) }
      Array(res.get_fields("set-cookie")).each do |cookie|
        name, value = cookie.split(";", 2).first.split("=", 2)
        jar[name.strip] = value.to_s
      end
      res
    end

    # All inputs of the consent form (hidden __VIEWSTATE0..N etc.) plus the OK button.
    def consent_form(uri, body)
      form = Nokogiri::HTML(body).at("form")
      fields = form.css("input[name]").reject { _1["type"] == "submit" && _1["name"] != "butAgree" }
      [ URI.join(uri, form["action"]), fields.to_h { [ _1["name"], _1["value"].to_s ] } ]
    end
  end
end
