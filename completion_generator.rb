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
    methods.inject({}) do |methods, method|
      selector = method['selector'].to_sym
      methods[selector] = {}

      methods[selector][:args] = method.css('arg').inject({}) do |args, arg|
        arg_name = (arg['name'] || arg['declared_type'].underscore.split('_')[1] || arg['declared_type']) # NSArray => array or BOOL
        arg_name += '1' if args.has_key?(arg_name) # array1 if array exists
        arg_name = arg_name.next while args.has_key?(arg_name) # keep incrementing while the key exists
        args[arg_name.to_sym] = arg['declared_type']
        args
      end

      methods[selector][:retval] = method.css('retval').first['declared_type']
      methods
    end
  end

  def parse_constants(constants)
  end
end

class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

class RubyMotionGrammarParser

end
