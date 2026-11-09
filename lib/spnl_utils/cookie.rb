module SpnlUtils
module Cookie
  def self.parse(header)
    out = {}
    header.split(';').each do |part|
      pair = part.strip.split('=', 2)
      next if pair[0].nil? || pair[0].empty?
      out[pair[0]] = pair.length == 2 ? pair[1] : ''
    end
    out
  end
  def self.build(name, value, path = '/', max_age = 0, http_only = true, secure = true, same_site = 'Lax')
    raise ArgumentError, 'invalid cookie name' unless name.match?(/\A[!#$%&'*+.^_`|~0-9A-Za-z-]+\z/)
    raise ArgumentError, 'invalid cookie value' if value.match?(/[\x00-\x20\x7f;,"\\]/)
    raise ArgumentError, 'invalid cookie path' if path.match?(/[\r\n;]/)
    raise ArgumentError, 'invalid SameSite' unless ['', 'Lax', 'Strict', 'None'].include?(same_site)
    raise ArgumentError, 'SameSite=None requires Secure' if same_site == 'None' && !secure
    parts = [name+'='+value]
    parts.push('Path='+path) unless path.empty?
    parts.push('Max-Age='+max_age.to_s) if max_age > 0
    parts.push('HttpOnly') if http_only
    parts.push('Secure') if secure
    parts.push('SameSite='+same_site) unless same_site.empty?
    parts.join('; ')
  end
  def self.strip(s); s.strip; end
end

end
