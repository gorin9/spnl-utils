require 'cgi'
module SpnlUtils
  module URL
    # Form encoding delegates byte and Unicode handling to the standard CGI API.
    def self.encode(value); CGI.escape(value); end
    def self.decode(value); CGI.unescape(value); end
    def self.parse_query(query)
      out = {}
      query.split('&').each do |part|
        pair = part.split('=', 2)
        next if pair[0].nil? || pair[0].empty?
        out[decode(pair[0])] = pair.length == 2 ? decode(pair[1]) : ''
      end
      out
    end
    def self.build_query(values)
      values.map { |key,value| encode(key.to_s)+'='+encode(value.to_s) }.join('&')
    end
  end
end
