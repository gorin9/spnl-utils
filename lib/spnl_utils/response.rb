module SpnlUtils
class Response
  attr_reader :status, :reason, :ctype, :body, :headers
  def initialize
    @status=200;@reason='OK';@ctype='text/plain; charset=utf-8';@body='';@headers={};@cookies=[]
  end
  def set_status(status,reason)
    raise ArgumentError, 'invalid status' unless status >= 200 && status <= 599
    validate_value(reason);@status=status;@reason=reason
  end
  def validate_value(value)
    raise ArgumentError, 'invalid header value' if value.match?(/[\x00-\x1f\x7f]/)
  end
  def set_ctype(value); validate_value(value);@ctype=value;end
  def set_body(value); @body=value;end
  def add_header(name,value)
    raise ArgumentError, 'invalid header name' unless name.match?(/\A[!#$%&'*+.^_`|~0-9A-Za-z-]+\z/)
    raise ArgumentError, 'managed header' if ['content-length','connection','transfer-encoding','set-cookie','content-type'].include?(name.downcase)
    validate_value(value);@headers[name]=value
  end
  def set_cookie(value);validate_value(value);@cookies.push(value);end
  def self.text(body);r=new;r.set_body(body);r;end
  def self.html(body);r=text(body);r.set_ctype('text/html; charset=utf-8');r;end
  def self.json_body(body);r=text(body);r.set_ctype('application/json; charset=utf-8');r;end
  def self.not_found;r=text("not found\n");r.set_status(404,'Not Found');r;end
  def self.bad_request(message);r=text(message);r.set_status(400,'Bad Request');r;end
  def self.redirect(location);r=text('');r.set_status(302,'Found');r.add_header('Location',location);r;end
  def to_wire(method = 'GET')
    forbidden = @status == 204 || @status == 304
    parts = ["HTTP/1.1 "+@status.to_s+' '+@reason+"\r\n", 'Content-Type: '+@ctype+"\r\n", "Connection: close\r\n"]
    parts.push('Content-Length: '+@body.bytesize.to_s+"\r\n") unless forbidden
    @headers.each do |k,v|
      raise ArgumentError, 'invalid header name' unless k.match?(/\A[!#$%&'*+.^_`|~0-9A-Za-z-]+\z/)
      raise ArgumentError, 'managed header' if ['content-length','connection','transfer-encoding','set-cookie','content-type'].include?(k.downcase)
      validate_value(v);parts.push(k+': '+v+"\r\n")
    end
    @cookies.each { |v| parts.push('Set-Cookie: '+v+"\r\n") }
    parts.push("\r\n")
    parts.push(@body) unless forbidden || method == 'HEAD'
    parts.join
  end
end

end
