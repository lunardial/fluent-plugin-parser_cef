# -*- coding: utf-8

require 'fluent/log'
require 'fluent/parser'
require 'time'
require 'yaml'

module Fluent
  class TextParser
    class CommonEventFormatParser < Parser

      Plugin.register_parser("cef", self)

      config_param :log_format, :string, :default => "syslog"
      config_param :syslog_timestamp_format, :string, :default => '\w{3}\s+\d{1,2}\s\d{2}:\d{2}:\d{2}'
      config_param :cef_version, :integer, :default => 0
      config_param :parse_strict_mode, :bool, :default => true
      config_param :cef_keyfilename, :string, :default => 'config/cef_version_0_keys.yaml'
      config_param :output_raw_field, :bool, :default => false


      def configure(conf)
        super

        @key_value_format_regexp = /([^\s=]+)=(.*?)(?:(?=[^\s=]+=)|\z)/
        @valid_format_regexp = create_valid_format_regexp

        begin
          if @parse_strict_mode
            if @cef_keyfilename =~ /^\//
              yaml_fieldinfo = YAML.load_file(@cef_keyfilename)
            else
              yaml_fieldinfo = YAML.load_file("#{File.dirname(File.expand_path(__FILE__))}/#{@cef_keyfilename}")
            end
            @keys_array = []
            yaml_fieldinfo.each {|_key, value| @keys_array.concat(value) }
            $log.info "running with strict mode, #{@keys_array.length} keys are valid."
          else
            $log.info "running without strict mode"
          end
        rescue => e
          @parse_strict_mode = false
          $log.warn "running without strict mode because of the following error"
          $log.warn "#{e.message}"
        end
      end


      def create_valid_format_regexp()
        case @log_format
        when "syslog"
          syslog_header = /
              (?<syslog_timestamp>#{@syslog_timestamp_format})\s
              (?<syslog_hostname>\S+)\s
              (?<syslog_tag>\S*)\s*
            /x
          cef_header = /
            CEF:(?<cef_version>#{@cef_version})\|
            (?<cef_device_vendor>[^|]*)\|
            (?<cef_device_product>[^|]*)\|
            (?<cef_device_version>[^|]*)\|
            (?<cef_device_event_class_id>[^|]*)\|
            (?<cef_name>[^|]*)\|
            (?<cef_severity>[^|]*)
          /x
          valid_format_regexp = /
              \A
                #{syslog_header}
                #{cef_header}\|
                (?<cef_extension>.*)
              \z
            /x
        else
          raise Fluent::ConfigError, "#{@log_format} is unknown format"
        end
        return Regexp.new(valid_format_regexp)
      end


      def parse(text)
        if text.nil? || text.empty?
          if block_given?
            yield nil, nil
            return
          else
            return nil, nil
          end
        end

        record = {}
        record_overview = @valid_format_regexp.match(text)
        if record_overview.nil?
          if block_given?
            yield Engine.now, { "raw" => text }
            return
          else
            return Engine.now, { "raw" => text }
          end
        end

        begin
          time = Time.parse(record_overview["syslog_timestamp"]).to_i
        rescue
          time = Engine.now
        end

        begin
          record_overview.names.each {|key| record[key] = record_overview[key] }
          text_cef_extension = record_overview["cef_extension"]
          record.delete("cef_extension")
        rescue
          if block_given?
            yield Engine.now, { "raw" => text }
            return
          else
            return Engine.now, { "raw" => text }
          end
        end

        unless text_cef_extension.nil?
          record_cef_extension = parse_cef_extension(text_cef_extension)
          record.merge!(record_cef_extension)
        end

        record["raw"] = text if @output_raw_field
        if block_given?
          yield time, record
          return
        else
          return time, record
        end
      end


      def parse_cef_extension(text)
        if @parse_strict_mode == true
          return parse_cef_extension_with_strict_mode(text)
        else
          return parse_cef_extension_without_strict_mode(text)
        end
      end


      def parse_cef_extension_with_strict_mode(text)
        record = {}
        begin
          last_valid_key_name = nil
          text.scan(@key_value_format_regexp) do |key, value|
            if @keys_array.include?(key)
              record[key] = value
              record[last_valid_key_name].rstrip! unless last_valid_key_name.nil?
              last_valid_key_name = key
            else
              record[last_valid_key_name].concat("#{key}=#{value}")
            end
          end
        rescue
          return {}
        end
        return record
      end


      def parse_cef_extension_without_strict_mode(text)
        record = {}
        begin
          text.scan(@key_value_format_regexp) {|key, value| record[key] = value.rstrip }
        rescue
          return {}
        end
        return record
      end
    end
  end
end
