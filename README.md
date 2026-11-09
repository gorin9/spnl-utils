# spnl-utils

Ruby/Spinel HTTP helpers built on standard JSON and CGI APIs.

```toml
[dependencies]
spnl_utils = { git = "https://github.com/gorin9/spnl-utils", ref = "modernize-spinel-2026" }
```

```ruby
require "spnl_utils"
request = SpnlUtils::Request.parse("GET /?q=%E9%9B%AA HTTP/1.1\r\nHost: example\r\n\r\n")
response = SpnlUtils::Response.json_body(JSON.generate({"q" => request.query["q"]}))
puts response.to_wire
```

`SpnlUtils::Request/Response/URL/Cookie/Router` are namespaced entry points.
Historical relative lib/ entry points remain compatible; require "spnl_utils/legacy"
explicitly to install all old top-level names. The default entry point installs none.
The gem adds the package root, not its lib/ directory, to avoid shadowing standard json.

## Migration from 0.1

JSON.parse now returns standard Hash/Array/scalar values. Replace
`value.get_field("name").s` with `value["name"]`, and `set_field`/`push_arr` with
Hash/Array operations. `JSON.encode` is a compatibility alias for standard generation;
`gen_*` return native Ruby values. The old JsonValue return contract cannot coexist
with standard JSON.parse and has been removed in this version.

URL.encode/decode are **form** encoding (+ for space), not URI path/component encoding.
parse_query keeps the last duplicate value, matching the old Hash contract; require "uri" and use
URI.decode_www_form directly when duplicate fields must be retained.

## HTTP contract

Request.parse accepts exactly one complete HTTP/1.0 or HTTP/1.1 origin-form request.
Request.read handles fragmented socket reads. Headers are capped at 16 KiB and bodies
at 1 MiB; HTTP/1.1 requires Host. Duplicate headers, conflicting framing, extra bytes,
invalid Content-Length and Transfer-Encoding are rejected. Chunked request bodies and
pipelining are not supported. This is a deliberately bounded HTTP subset, not Rack.
Deploy behind a proxy that sends Content-Length requests when chunked uploads are needed.

Responses close the connection, preserve multiple Set-Cookie values, reject header
injection, omit bodies for HEAD/204/304 and prevent conflicting managed headers.
Cookie.build defaults to Secure + HttpOnly + SameSite=Lax; opt out of Secure only for
local HTTP. The route matcher preserves segment boundaries; spnl-router provides
validated static HTTP dispatch generation.

## Compatibility and verification

Supported baseline: Spinel `2026.10.25` (Linux) and CRuby 3.1+. CI also checks the
reference master commit `60c0273261415d2b5edd6480667a705a68addbd2`; this is a pinned
comparison, not an assertion about every future master build. Check CHANGELOG before upgrading.
No performance or binary-size claim is inherited from the May prototype.

Run `rake test`. Runtime packages additionally use `spin test`; generator repositories
use `ruby scripts/verify_runtime.rb` to compile their generated code and compare with CRuby.
See CONTRIBUTING.md. Original notes are in `docs/historical-readme-may-2026.md`.

MIT licensed. Development version; no gem or package-index release is published automatically.
