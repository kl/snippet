
class RubyFormatter

  KEYWORDS = %w(def end do begin rescue raise class module if else case)

  def format(text)
    result = text.gsub(/(#{KEYWORDS.join("|")})/, '<span class="keyword">\1</span>')
    #binding.pry
    result
  end

end