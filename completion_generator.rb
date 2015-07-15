#! /usr/bin/env ruby

require 'nokogiri'
require 'json'

class RubyMotionCompletionGenerator
  attr_accessor :dir

  def initialize(dir)
    @dir = dir
    @completions = {}
    @completions[:functions] = {}
    @completions[:methods] = {}
    @completions[:constants] = {}
    @completions[:enums] = {}
    @completions[:classes] = []
  end
  
  def generate
    Dir.glob("#{@dir}/*").each do |file|
      next if File.directory? file

      file = File.read(file)
      doc = Nokogiri::XML(file)

      functions = parse_functions(doc.css('function')) do |function_hash, function|
        function_hash[:args] = parse_args(function.css('arg')) do |arg_hash, arg|
          arg_hash << arg['declared_type']
        end

        function_hash[:retval] = function.css('retval').first['declared_type']
      end

      methods = parse_methods(doc.css('method'), name_attribute: 'selector') do |method_hash, method|
        method_hash[:args] = parse_args(method.css('arg'))  do |arg_hash, arg|
          arg_hash << arg['declared_type']
        end

        method_hash[:retval] = method.css('retval').first['declared_type']
      end

      constants = parse_constants(doc.css('constant')) do |constant_hash, constant|
        constant_hash << constant['declared_type']
      end

      enums = parse_enums(doc.css('enum')) do |enum_hash, enum|
        enum_hash << enum['value']
      end

      @completions[:functions].merge!(functions)

      @completions[:methods].merge!(methods)

      @completions[:constants].merge!(constants)

      @completions[:constants].merge!(enums)

      (@completions[:classes] << parse_classes(doc.css('class'))).flatten!
    end

    Dir.chdir(File.dirname(__FILE__))
    File.open('completions.json', 'w') { |file| file.write(JSON.pretty_generate(@completions)) }

  end

  def parse(nodes, options={})
    node_attr = options.fetch(:name_attribute, 'name')

    nodes.each_with_object({}) do |node, nodes|
      if node_attr.is_a? Proc
        node_name = node_attr.call(node)
      else
        node_name = node[node_attr]
      end

      return if node_name.nil? || node_name.respond_to?(:to_sym) == false

      if %w[constant enum arg].include? node.name
        if nodes.has_key? node_name
          node_name += '1'  # ex. 'array1' if 'array' key exists
          node_name.next! while nodes.has_key? node_name # keep incrementing while the key exists
        end

        nodes[node_name.to_sym] = ''
      else
        nodes[node_name.to_sym] = {}
      end

      yield nodes[node_name.to_sym], node if block_given?
    end
  end

  def parse_args(args, &block)
    name_selector = ->(arg){ arg['name'] || arg['declared_type'].underscore.split('_')[1] || arg['declared_type'] }
    parse(args, name_attribute: name_selector, &block)
  end

  def parse_classes(classes)
    classes.map {|klass| klass['name']}
  end

  def method_missing(method_sym, *args, &block)
    if method_sym.to_s =~ /^parse_(.*)$/
      parse(*args, &block)
    else
      super
    end
  end

  def respond_to?(method_sym)
    if method_sym.to_s =~ /^parse_(.*)$/
      true
    else
      super
    end
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

dir = ARGV.shift
RubyMotionCompletionGenerator.new(dir).generate
