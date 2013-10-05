#encoding: utf-8

#
# A somewhat generic formatter/parser that can add tags to text in order to
# show for example syntax highlighting. This is the base class implementation for
# the formatter, and the subclasses provide the format specific formatting.
#
class Formatter

  class TokenMatcher

    def initialize(token_regex, proc, options = {})
      @regex = token_regex
      @proc = proc
      @options = {allow_left: false, allow_right: false, partial: false}
      @options.merge!(options)
    end

    def regex
      left = parse_option(@options[:allow_left])
      right = parse_option(@options[:allow_right])

      /#{/\A/}#{left}#{@regex}#{right}#{/\z/}/
    end

    def apply_proc(token)
      if @options[:partial]
        part = token[@regex]
        result = @proc.call(part.dup)
        token.sub(part, result)
      else
        @proc.call(token)
      end
    end

    private

    def parse_option(option)
      return option if option.is_a?(Regexp)
      case option
      when :any then /.*/m
      when false then ""
      end
    end
  end

  class NoparseMatcher

    def initialize(start, stop, proc)
      @start = start
      @stop = stop
      @proc = proc
    end

    def is_noparse_start?(token)
      /\A#{@start}/ =~ token
    end

    def is_noparse_stop?(token)
      # Match any character followed by the stop sequence (prevents false match if the start
      # and the stop sequence are the same)
      /.#{@stop}/ =~ token 
    end

    def callback(type, token)
      @proc.call(type, token)
    end
  end

  # A substring is any non-whitespace characters followed by all whitespace
  # until the next non-whitespace character.
  SUBSTRING_REGEX = /.+?(?:\s+|\z)/m

  # A token contains non-whitespace character. This regex extracts the token and whitespace
  # part from a substring.
  TOKEN_REGEX = /\A([^\s]+?)(\s+|\z)/

  def initialize
    @token_matchers = []
    @noparse_matchers = []
    @parsing = true
  end

  def format(text)
    result = ""

    text.scan(SUBSTRING_REGEX) do |substring|

      token, whitespace = substring.scan(TOKEN_REGEX).flatten
      unless token.nil? || token.empty?
        result << process_token(token) + whitespace
      else
        result << substring
      end
    end

    result
  end

  private

  def register_token(token_regex, options = {}, &proc)
    @token_matchers << TokenMatcher.new(token_regex, proc, options)
  end

  def register_noparse(start, stop, &proc)
    @noparse_matchers << NoparseMatcher.new(start, stop, proc)
  end

  def process_token(token)
    if @parsing
      get_parsing_result(token)
    else
      get_no_parsing_result(token)
    end
  end

  def get_parsing_result(token)
    if @current_noparse = get_noparse_matcher(token)
      @parsing = false
      result = @current_noparse.callback(:start, token)

      if @current_noparse.is_noparse_stop?(token)
        @parsing = true
        result = @current_noparse.callback(:stop, result)
      end
      result
    else
      parse_token(token)
    end
  end

  def get_no_parsing_result(token)
    if @current_noparse.is_noparse_stop?(token)
      @parsing = true
      @current_noparse.callback(:stop, token)
    else
      token
    end
  end

  def get_noparse_matcher(token)
    @noparse_matchers.find { |matcher| matcher.is_noparse_start?(token) }
  end

  def parse_token(token)
    matcher = @token_matchers.find { |matcher| matcher.regex =~ token }
    matcher ? matcher.apply_proc(token) : token
  end

  # Helper for subclasses to use
  def span_tag(class_name, token)
    "<span class='#{class_name}'>#{token}</span>"
  end
end
