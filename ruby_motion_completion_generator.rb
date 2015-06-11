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
    @completions[:classes] = []
  end

  def generate(dir)
    Dir.glob("#{dir}/*").each do |file|
      next if File.directory?(file)

      file = File.read(file)
      doc = Nokogiri::XML(file)

      @completions[:functions].merge!(parse_functions(doc.css('function')))

      @completions[:methods].merge!(parse_methods(doc.css('method')))

      @completions[:constants].merge!(parse_constants(doc.css('constant')))

      (@completions[:classes] << parse_classes(doc.css('class'))).flatten!
    end

    JSON.pretty_generate(@completions)
  end

  def parse(nodes, options={})
    node_attr = options.fetch(:name_attribute, 'name')

    nodes.each_with_object({}) do |node, nodes|
      if node_attr.is_a? Proc
        # p 'was a proc'
        node_name = node_attr.call(node)
      else
        # p 'wasnt proc'
        node_name = node[node_attr]
      end

      return if node_name.nil? || node_name.respond_to?(:to_sym) == false

      if %w[constant arg].include? node.name
        if nodes.has_key?(node_name)
          node_name += '1'  # ex. 'array1' if 'array' key exists
          node_name.next! while nodes.has_key?(node_name) # keep incrementing while the key exists
        end

        nodes[node_name.to_sym] = ''
      else
        nodes[node_name.to_sym] = {}
      end

      yield nodes[node_name.to_sym], node
    end
  end

  def parse_functions(functions)
    parse(functions) do |function_hash, function|

      function_hash[:args] = parse_args(function.css('arg')) do |arg_hash, arg|
        arg_hash << arg['declared_type']
      end

      function_hash[:retval] = function.css('retval').first['declared_type']
    end
  end

  def parse_args(args, &block)
    name_selector = ->(arg){ arg['name'] || arg['declared_type'].underscore.split('_')[1] || arg['declared_type'] }
    parse(args, name_attribute: name_selector, &block)
  end

  def parse_methods(methods)
    parse(methods, name_attribute: 'selector') do |method_hash, method|
      method_hash[:args] = parse_args(method.css('arg'))  do |arg_hash, arg|
        arg_hash << arg['declared_type']
      end

      method_hash[:retval] = method.css('retval').first['declared_type']
    end
  end

  def parse_constants(constants)
    parse(constants) do |constant_hash, constant|
      constant_hash << constant['declared_type']
    end
  end

  def parse_classes(classes)
    classes.map {|klass| klass['name']}
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
