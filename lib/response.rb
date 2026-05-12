# HTTP response representation for Spinel.
#
# Usage:
#   res = Response.text("hello")           # 200 text/plain
#   res = Response.html("<h1>Hi</h1>")     # 200 text/html
#   res = Response.json_body(json_str)     # 200 application/json
#   res = Response.not_found
#   res = Response.redirect("/")
#
# 送信:
#   wire = res.to_wire        # HTTP/1.0 ... \r\n\r\n + body
#   write to socket

class Response
  def initialize
    @status = 200
    @reason = "OK"
    @ctype = "text/plain; charset=utf-8"
    @body = ""
    @headers = { "_seed" => "x" }
    @headers.delete("_seed")
  end

  def status; @status; end
  def reason; @reason; end
  def ctype; @ctype; end
  def body; @body; end
  def headers; @headers; end

  def set_status(s, r)
    @status = s
    @reason = r
  end
  def set_ctype(c); @ctype = c; end
  def set_body(b); @body = b; end
  def add_header(k, v)
    @headers[k] = v
  end
  def set_cookie(c)
    @headers["Set-Cookie"] = c
  end

  # ---- builders ----
  def self.text(body)
    r = Response.new
    r.set_ctype("text/plain; charset=utf-8")
    r.set_body(body)
    r
  end

  def self.html(body)
    r = Response.new
    r.set_ctype("text/html; charset=utf-8")
    r.set_body(body)
    r
  end

  def self.json_body(json_str)
    r = Response.new
    r.set_ctype("application/json; charset=utf-8")
    r.set_body(json_str)
    r
  end

  def self.not_found
    r = Response.new
    r.set_status(404, "Not Found")
    r.set_body("not found\n")
    r
  end

  def self.bad_request(msg)
    r = Response.new
    r.set_status(400, "Bad Request")
    r.set_body(msg)
    r
  end

  def self.redirect(loc)
    r = Response.new
    r.set_status(302, "Found")
    r.add_header("Location", loc)
    r.set_body("")
    r
  end

  # 送信用の HTTP/1.0 ワイヤ表現を返す。
  def to_wire
    parts = ["seed"]
    parts.clear
    parts.push("HTTP/1.0 ")
    parts.push(@status.to_s)
    parts.push(" ")
    parts.push(@reason)
    parts.push("\r\n")
    parts.push("Content-Type: ")
    parts.push(@ctype)
    parts.push("\r\n")
    parts.push("Content-Length: ")
    parts.push(@body.bytesize.to_s)
    parts.push("\r\n")
    parts.push("Connection: close\r\n")

    # ユーザー追加ヘッダ
    @headers.each do |k, v|
      parts.push(k)
      parts.push(": ")
      parts.push(v)
      parts.push("\r\n")
    end

    parts.push("\r\n")
    parts.push(@body)
    parts.join("")
  end
end
