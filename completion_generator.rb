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

      # parse_functions(doc.css('function'))

      parse_methods(doc.css('method'))

      # parse_constants(doc.css('constant'))

    end
  end

  def parse_functions(functions)
  end

  def parse_methods(methods)
  end

  def parse_constants(constants)
    constants.each_with_object({}) do |constant, constants|
      const_name = constant['name']
      constants[const_name] = constant['declared_type']
    end
  end
end


class RubyMotionGrammarParser

end
