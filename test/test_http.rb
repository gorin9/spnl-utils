require 'stringio'
require_relative '../spnl_utils'
def assert(x,m);raise m unless x;end
assert(JSON.parse('{"a":1}')['a']==1,'standard JSON')
['truX','{"a":1} trailing','"unterminated'].each do |v|
  begin;JSON.parse(v);raise 'invalid JSON accepted';rescue JSON::ParserError;end
end
assert(JSON.parse('"\u0041"')=='A','unicode JSON')
assert(SpnlUtils::URL.decode(SpnlUtils::URL.encode('日本語 +'))=='日本語 +','UTF-8 URL')
raw="POST /x?q=%E9%9B%AA HTTP/1.1\r\nHost: example\r\nContent-Length: 3\r\nCookie: a=1; b=2\r\n\r\na\x00b"
req=SpnlUtils::Request.parse(raw)
assert(req.body.bytesize==3 && req.query['q']=='雪' && req.cookies['b']=='2','request frame')
class Pieces
  def initialize(s);@s=s;end
  def readpartial(n);raise EOFError if @s.empty?;x=@s.byteslice(0,[n,2].min);@s=@s.byteslice(x.bytesize,@s.bytesize);x;end
end
assert(SpnlUtils::Request.read(Pieces.new(raw)).body==req.body,'partial reads')
["GET / HTTP/1.1\r\nHost: x\r\nContent-Length: 0\r\nContent-Length: 1\r\n\r\n", "GET / HTTP/1.1\r\nHost: x\r\nTransfer-Encoding: chunked\r\n\r\n", raw+'x'].each do |v|
  begin;SpnlUtils::Request.parse(v);raise 'bad frame accepted';rescue ArgumentError;end
end
res=SpnlUtils::Response.text('雪');res.set_cookie('a=1');res.set_cookie('b=2')
assert(res.to_wire.scan('Set-Cookie:').length==2,'multiple cookies')
assert(res.to_wire('HEAD').end_with?("\r\n\r\n"),'HEAD')
res.set_status(204,'No Content');assert(!res.to_wire.include?('Content-Length:') && !res.to_wire.end_with?('雪'),'204')
begin;SpnlUtils::Response.redirect("/\r\nInjected: yes");raise 'injection accepted';rescue ArgumentError;end
puts 'JSON, UTF-8, partial HTTP framing, cookies and response semantics passed'
