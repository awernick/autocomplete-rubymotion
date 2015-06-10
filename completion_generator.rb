require 'nokogiri'
require 'json'

# TODO:
# 1. Verify RubyMotion is installed
# 2. Get latest BridgeSupport folder
# 3. Get all files inside folder
# 4. Process each through nokogiri

# Options:
# 1. Allow selection of IOS, Android, or OSX or all

RUBYMOTION_PATH =  ARGV.first || '/Library/RubyMotion/ios/data'

class RubyMotionCompletionGenerator
  attr_accessor :dir

  def initialize(dir)
    @dir = dir
    @completions = {}
  end

  def generate(dir)
    Dir.chdir(dir)

    Dir.entries(dir).each do |file|
      return if File.directory?(file)

      file = File.read(file)
      doc = Nokogiri::XML(file)

      @completions['functions'] = parse_functions(doc.css('function'))

      # parse_methods(doc.css('method'))

      # parse_constants(doc.css('constant'))

    end
  end

  def parse_functions(functions)
    functions.each_with_object({}) do |function, functions|
      args = {}

      function.css('arg').each_with_object(args) do |arg, args|
        args[arg['name'].to_sym] = arg['declared_type']
      end

      function_name = function['name']
      functions[function_name.to_sym] = args
    end
  end

  def parse_methods(methods)
  end

  def parse_constants(constants)
  end
end


class RubyMotionGrammarParser

end
