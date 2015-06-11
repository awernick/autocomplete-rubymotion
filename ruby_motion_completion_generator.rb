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
      # p node.name
      # p node_name

      return if node_name.nil?
      # p node.name
      if %w[constant arg].include? node.name 
        nodes[node_name.to_sym] = ''
        # p nodes[node_name.to_sym].inspect
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

    # functions.each_with_object({}) do |function, functions|
    #   function_name = function['name']
    #   functions[function_name.to_sym] = {}
    #    args = {}
    #
    #   function.css('arg').each_with_object(args) do |arg, args|
    #     arg_name = (arg['name'] || arg['declared_type'].underscore[1] || arg['declared_type']).to_sym
    #     args[arg_name] = arg['declared_type']
    #   end
    #
    #   functions[function_name.to_sym][:args] = args
    #   functions[function_name.to_sym][:retval] = function.css('retval').first['declared_type']
    # end
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

    # methods.each_with_object({}) do |method, methods|
    #   selector = method['selector'].to_sym
    #   methods[selector] = {}
    #
    #   methods[selector][:args] = method.css('arg').each_with_object({}) do |arg, args|
    #     arg_name = (arg['name'] || arg['declared_type'].underscore.split('_')[1] || arg['declared_type']) # NSArray => array or BOOL
    #
    #     if args.has_key?(arg_name)
    #       arg_name += '1'  # ex. 'array1' if 'array' key exists
    #       arg_name = arg_name.next while args.has_key?(arg_name) # keep incrementing while the key exists
    #     end
    #
    #     args[arg_name.to_sym] = arg['declared_type']
    #   end
    #
    #   methods[selector][:retval] = method.css('retval').first['declared_type']
    # end
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
