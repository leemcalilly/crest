class ApplicationController < ActionController::Base
  # crest is a public, read-only site. Every reader is welcome, including
  # agent browsers and command-line clients, so no browser gate is applied:
  # `allow_browser versions: :modern` answers 406 to anything it does not
  # recognise, which would shut out the WebMCP clients this site is built for.
end
