# Reference-master composition limitation

At master 60c02732, combining the full bundled URI implementation with the SQLite3
C-extension runtime in the demo generated an incompatible const char*/sp_String*
assignment in URI::RFC3986_Parser#split (uri.rb:1799). The ordinary URI and SQLite
smokes each compiled separately. No warning/error flag was disabled and no compiler
patch is shipped here.

The package only needs form component escaping, so its supported implementation
uses standard CGI.escape/unescape instead of loading the full URI parser. The same
choice is used by the CSRF query helper. URI is still available to applications
that explicitly require it; the problematic composition is outside this package's
pinned integration contract until upstream resolves it.
