#encoding: utf-8

require_relative 'base'

class JavaFormatter < Formatter

  KEYWORDS = %w(public private protected static class interface if else switch instanceof extends implements void)

  def initialize
    super

    # Keywords
    register_token(/#{KEYWORDS.join("|")}/) { |keyword| span_tag "keyword", keyword }

    # Strings
    register_noparse('"', '"', &string_callback) 
    register_noparse("'", "'", &string_callback)
    register_noparse("&quot;", "&quot;", &string_callback)
    register_noparse("&#x27;", "&#x27;", &string_callback)

    # "Embedded" strings
    register_token(/&quot;.+?&quot;/, allow_left: :any, allow_right: :any, partial: true) do |string|
      require 'pry'; binding.pry
      span_tag "string", string
    end
  end

  def string_callback
    lambda do |type, token|
      return "<span class='string'>#{token}" if type == :start 
      return "#{token}</span>"               if type == :stop 
    end
  end

end
