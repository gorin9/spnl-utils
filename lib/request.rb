# HTTP request representation for Spinel.
#
# 構築は Request.parse(raw_request_text) で行う想定。
# パース結果は immutable に近いが、Spinel は frozen を持たないので慣習で。
#
# Usage:
#   req = Request.parse(raw)
#   req.method               # "GET"
#   req.path                 # "/users/42"     (query string 除く)
#   req.full_path            # "/users/42?x=1" (生)
#   req.header("Host")       # "example.com"
#   req.query["x"]           # "1"
#   req.cookies["session"]   # "abc"
#   req.body                 # ""

class Request
  def initialize
    @method = ""
    @path = ""
    @full_path = ""
    @version = ""
    # ヘッダ: 小文字キー化された str_str_hash
    @headers = { "_seed" => "x" }
    @headers.delete("_seed")
    @body = ""
    @query = { "_seed" => "x" }
    @query.delete("_seed")
    @cookies = { "_seed" => "x" }
    @cookies.delete("_seed")
  end

  def method; @method; end
  def path; @path; end
  def full_path; @full_path; end
  def version; @version; end
  def headers; @headers; end
  def body; @body; end
  def query; @query; end
  def cookies; @cookies; end

  def header(k)
    @headers[Request.lower(k)]
  end

  def set_method(m); @method = m; end
  def set_path(p); @path = p; end
  def set_full_path(p); @full_path = p; end
  def set_version(v); @version = v; end
  def set_body(b); @body = b; end
  def add_header(k, v)
    @headers[Request.lower(k)] = v
  end
  def set_query(q); @query = q; end
  def set_cookies(c); @cookies = c; end

  # ASCII lower
  def self.lower(s)
    out = ""
    n = s.bytesize
    i = 0
    while i < n
      c = s.slice(i, 1)
      b = c.ord
      if b >= 65 && b <= 90
        out = out + (b + 32).chr
      else
        out = out + c
      end
      i += 1
    end
    out
  end

  # 生のリクエスト文字列 (request line + headers + "\r\n\r\n" + body) をパース。
  # body 長は Content-Length に従う。本実装は header 部のみ扱い、
  # 呼び出し側で body は別途読む想定。
  def self.parse(raw)
    req = Request.new
    # split into lines
    nl = raw.index("\r\n")
    if nl == nil || nl < 0
      return req
    end
    line1 = raw.slice(0, nl)
    Request.parse_request_line(req, line1)

    # headers
    pos = nl + 2
    end_pos = raw.bytesize
    forever = true
    while forever
      nl2 = Request.index_from(raw, "\r\n", pos)
      if nl2 < 0
        forever = false
      else
        if nl2 == pos
          # blank line: end of headers
          pos = nl2 + 2
          forever = false
        else
          line = raw.slice(pos, nl2 - pos)
          Request.parse_header_line(req, line)
          pos = nl2 + 2
        end
      end
    end

    # body (residual)
    if pos < end_pos
      req.set_body(raw.slice(pos, end_pos - pos))
    end

    # query
    full = req.full_path
    qpos = full.index("?")
    if qpos != nil && qpos >= 0
      qs = full.slice(qpos + 1, full.bytesize - qpos - 1)
      req.set_query(URL.parse_query(qs))
      req.set_path(full.slice(0, qpos))
    end

    # cookies
    ck = req.header("cookie")
    if ck != nil && ck.bytesize > 0
      req.set_cookies(Cookie.parse(ck))
    end

    req
  end

  def self.parse_request_line(req, line)
    sp1 = line.index(" ")
    if sp1 == nil || sp1 < 0
      return
    end
    sp2 = Request.index_from(line, " ", sp1 + 1)
    if sp2 < 0
      return
    end
    req.set_method(line.slice(0, sp1))
    req.set_full_path(line.slice(sp1 + 1, sp2 - sp1 - 1))
    req.set_path(req.full_path)
    req.set_version(line.slice(sp2 + 1, line.bytesize - sp2 - 1))
  end

  def self.parse_header_line(req, line)
    cp = line.index(":")
    if cp == nil || cp < 0
      return
    end
    k = line.slice(0, cp)
    v = line.slice(cp + 1, line.bytesize - cp - 1)
    # trim leading spaces in v
    while v.bytesize > 0 && v.slice(0, 1) == " "
      v = v.slice(1, v.bytesize - 1)
    end
    req.add_header(k, v)
  end

  # Spinel String#index は開始位置指定がない (引数1つ) ので自前。
  def self.index_from(s, needle, start)
    n = s.bytesize
    nlen = needle.bytesize
    i = start
    while i + nlen <= n
      if s.slice(i, nlen) == needle
        return i
      end
      i += 1
    end
    -1
  end
end
