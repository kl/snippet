#encoding: utf-8

require_relative 'base'

class RubyFormatter < Formatter

  KEYWORDS = %w(def end do begin rescue raise class module if else case)

  def initialize
    super

    # Symbols
    register_token /:\w+/, allow_left: :any, allow_right: :any, partial: true do |symbol|
      span_tag "symbol", symbol
    end

    register_token(/\w+:/) { |symbol| span_tag "symbol", symbol } 

    # Keywords
    register_token(/#{KEYWORDS.join("|")}/) { |keyword| span_tag "keyword", keyword }

    # Instance variables
    register_token(/@\w+/, allow_right: :any, partial: true) do |ie|
      span_tag "instance_variable", ie
    end

    # Strings
    register_noparse('"', '"', &string_callback) 
    register_noparse("'", "'", &string_callback)
    register_noparse("&quot;", "&quot;", &string_callback)
    register_noparse("&#x27;", "&#x27;", &string_callback)

    # "Embedded" strings
    register_token(/&quot;.+?&quot;/, allow_left: :any, allow_right: :any, partial: true) do |string|
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

if __FILE__ == $0

require 'pry'

test = '  post "/snippet/new" do
    snippet = Snippet.new user_id: current_user.id,
                          title: params["name"],
                          text: params["snippet"],
                          type: params["type"]

    if snippet.save
      flash[:success] = "Snippet created def successfully"
      redirect "/snippet/#{snippet.id}"
    else
      flash[:error] = format_errors(snippet.errors)
      redirect "/snippet/new"
    end
  end'

rf = RubyFormatter.new
result = rf.format(test)

binding.pry

end
