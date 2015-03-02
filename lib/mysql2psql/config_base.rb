require 'yaml'
require 'mysql2psql/errors'
require 'erb'

class Mysql2psql
  class ConfigBase
    attr_reader :config

    def initialize(yaml)
      @config = yaml

      # Process any ERB in the config.
      nested_each(@config)
    end

    def nested_each(hash)
      hash.each_pair do |k,v|
        if v.is_a?(Hash)
          nested_each(v)
        else
          has_erb = v.is_a?(String) ? v.include?('<%=') : false
          if has_erb
            renderer = ERB.new(v)
            output = renderer.result()
            hash[k] = output
          end
        end
      end
    end

    def [](key)
      send(key)
    end

    def method_missing(name, *args)
      token = name.to_s
      default = args.length > 0 ? args[0] : ''
      must_be_defined = default == :none
      case token
      when /mysql/i
        key = token.sub(/^mysql/, '')
        value = config['mysql'][key]
      when /dest/i
        key = token.sub(/^dest/, '')
        value = config['destination'][key]
      when /only_tables/i
        value = config['tables']
      else
        value = config[token]
      end
      value.nil? ? (must_be_defined ? (fail Mysql2psql::UninitializedValueError.new("no value and no default for #{name}")) : default) : value
    end
  end
end
