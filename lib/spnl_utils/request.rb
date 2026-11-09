module SpnlUtils
require_relative 'url'
require_relative 'cookie'
class Request
  MAX_HEADER_BYTES = 16_384
  MAX_BODY_BYTES = 1_048_576
  attr_reader :method, :path, :full_path, :version, :headers, :body, :query, :cookies
  def initialize
    @method = ''; @path = ''; @full_path = ''; @version = ''
    @headers = {}; @body = ''; @query = {}; @cookies = {}
  end
  def header(name); @headers[name.downcase]; end
  def self.lower(value); value.downcase; end
  def self.index_from(value, needle, offset); value.index(needle, offset); end
  def self.parse(raw)
    boundary = raw.index("\r\n\r\n")
    raise ArgumentError, 'incomplete HTTP headers' if boundary.nil?
    raise ArgumentError, 'headers too large' if boundary > MAX_HEADER_BYTES
    lines = raw.byteslice(0, boundary).split("\r\n")
    request_line = lines.shift
    raise ArgumentError, 'invalid request line' unless request_line.match?(/\A[A-Z]+ [^ \t\r\n]+ HTTP\/1\.[01]\z/)
    fields = request_line.split(' ')
    raise ArgumentError, 'invalid request line' unless fields.length == 3 && fields[0].match?(/\A[A-Z]+\z/) && fields[1].start_with?('/') && ['HTTP/1.0','HTTP/1.1'].include?(fields[2])
    req = Request.new
    req.set_method(fields[0]);req.set_full_path(fields[1]);req.set_version(fields[2])
    lines.each do |line|
      pair = line.split(':', 2)
      raise ArgumentError, 'invalid header' unless pair.length == 2 && pair[0].match?(/\A[!#$%&'*+.^_`|~0-9A-Za-z-]+\z/) && !pair[1].match?(/[\x00-\x08\x0a-\x1f\x7f]/)
      key = pair[0].downcase
      raise ArgumentError, 'duplicate header' if req.headers.key?(key)
      req.add_header(key, pair[1].strip)
    end
    raise ArgumentError, 'Host required' if req.version == 'HTTP/1.1' && (req.header('host').nil? || req.header('host').empty?)
    raise ArgumentError, 'Transfer-Encoding unsupported' unless req.header('transfer-encoding').nil?
    length_header = req.header('content-length')
    raise ArgumentError, 'invalid Content-Length' if !length_header.nil? && !length_header.match?(/\A[0-9]+\z/)
    length = length_header.nil? ? 0 : length_header.to_i
    raise ArgumentError, 'body too large' if length > MAX_BODY_BYTES
    body = raw.byteslice(boundary+4, raw.bytesize-boundary-4)
    raise ArgumentError, 'body length mismatch' unless body.bytesize == length
    req.set_body(body)
    pieces = req.full_path.split('?', 2)
    req.set_path(pieces[0]);req.set_query(URL.parse_query(pieces.length == 2 ? pieces[1] : ''))
    cookie = req.header('cookie')
    req.set_cookies(Cookie.parse(cookie.nil? ? '' : cookie))
    req
  end
  # One framed request per connection; pipelining and chunked input are rejected.
  def self.read(io)
    raw = +''
    boundary = nil
    while boundary.nil?
      raw << io.readpartial(4096)
      boundary = raw.index("\r\n\r\n")
      raise ArgumentError, 'headers too large' if boundary.nil? && raw.bytesize > MAX_HEADER_BYTES
    end
    raise ArgumentError, 'headers too large' if boundary > MAX_HEADER_BYTES
    header = raw.byteslice(0, boundary)
    matches = header.scan(/(?:\A|\r\n)[Cc][Oo][Nn][Tt][Ee][Nn][Tt]-[Ll][Ee][Nn][Gg][Tt][Hh]:[ \t]*([0-9]+)[ \t]*(?=\r\n|\z)/)
    size = matches.empty? ? 0 : matches[0][0].to_i
    raise ArgumentError, 'body too large' if size > MAX_BODY_BYTES
    expected = boundary+4+size
    raw << io.readpartial([4096, expected-raw.bytesize].min) while raw.bytesize < expected
    parse(raw)
  end
  def set_method(v); @method=v; end
  def set_path(v); @path=v; end
  def set_full_path(v); @full_path=v; end
  def set_version(v); @version=v; end
  def set_body(v); @body=v; end
  def add_header(k,v); @headers[k.downcase]=v; end
  def set_query(v); @query=v; end
  def set_cookies(v); @cookies=v; end
end

end
