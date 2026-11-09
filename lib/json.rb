# Compatibility entry point. JSON.parse/generate now use Ruby's standard API.
require "json"
module JSON
  def self.encode(value); generate(value); end
  def self.gen_nil; nil; end
  def self.gen_bool(v); !!v; end
  def self.gen_int(v); v.to_i; end
  def self.gen_flt(v); v.to_f; end
  def self.gen_str(v); v.to_s; end
  def self.gen_arr; []; end
  def self.gen_obj; {}; end
end
