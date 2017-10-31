#-*- coding: utf-8 -*-

require 'fluent/plugin/parser_cef'
require 'fluent/test'
require 'fluent/test/driver/parser'

RSpec.describe Fluent::Plugin::CommonEventFormatParser do

  DEFAULT_CONFIGURE = %[
    log_format  syslog
    syslog_timestamp_format  \\w{3}\\s+\\d{1,2}\\s\\d{2}:\\d{2}:\\d{2}
    cef_version  0
    parse_strict_mode  true
    cef_keyfilename  'config/cef_version_0_keys.yaml'
    output_raw_field  false
  ]
  def create_driver(conf=DEFAULT_CONFIGURE)
    Fluent::Test::Driver::Parser.new(Fluent::Plugin::CommonEventFormatParser).configure(conf)
  end

  before :all do
    Fluent::Test.setup
  end

  before :each do
    @test_driver = create_driver
  end

  describe "#parse(text)" do

    context "text == nil" do
      let (:text) { nil }
      subject do
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to eq [nil, nil] }
    end
    context "text is empty string" do
      let (:text) { "" }
      subject do
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to eq [nil, nil] }
    end
    context "text is not syslog format nor CEF" do
      let (:text) { "December 12 10:00:00 hostname tag message" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to contain_exactly(be_an(Fluent::EventTime), { "raw" => "December 12 10:00:00 hostname tag message" }) }
    end
    context "text is not in syslog format but is CEF" do
      let (:text) { "December 12 10:00:00 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|cs1=test" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to contain_exactly(be_an(Fluent::EventTime), { "raw" => "December 12 10:00:00 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|cs1=test" }) }
    end
    context "text is syslog format but not CEF" do
      let (:text) { "Dec 12 10:11:12 hostname tag message" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to contain_exactly(be_an(Fluent::EventTime), { "raw" => "Dec 12 10:11:12 hostname tag message" }) }
    end
    context "text is syslog format and CEF (CEF Extension field is empty)" do
      let (:text) { "Dec  2 03:17:06 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        @timestamp = Time.parse("Dec  2 03:17:06").to_i
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to eq [
        @timestamp, {
          "syslog_timestamp" => "Dec  2 03:17:06",
          "syslog_hostname" => "hostname",
          "syslog_tag" => "tag",
          "cef_version" => "0",
          "cef_device_vendor" => "Vendor",
          "cef_device_product" => "Product",
          "cef_device_version" => "Version",
          "cef_device_event_class_id" => "ID",
          "cef_name" => "Name",
          "cef_severity" => "Severity" }]}
    end
    context "text is syslog format and CEF (there is only one valid key in the CEF Extension field), Strict mode on" do
      let (:text) { "Dec  2 03:17:06 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|cs1=test" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        @timestamp = Time.parse("Dec  2 03:17:06").to_i
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to eq [
        @timestamp, {
          "syslog_timestamp" => "Dec  2 03:17:06",
          "syslog_hostname" => "hostname",
          "syslog_tag" => "tag",
          "cef_version" => "0",
          "cef_device_vendor" => "Vendor",
          "cef_device_product" => "Product",
          "cef_device_version" => "Version",
          "cef_device_event_class_id" => "ID",
          "cef_name" => "Name",
          "cef_severity" => "Severity",
          "cs1" => "test" }]}
    end
    context "text is syslog format and CEF (there is only one valid key in the CEF Extension field), Strict mode off" do
      let (:config) {%[
        parse_strict_mode  false
      ]}
      let (:text) { "Dec  2 03:17:06 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|foo=bar" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        @timestamp = Time.parse("Dec  2 03:17:06").to_i
        @test_driver = create_driver(config)
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to eq [
        @timestamp, {
          "syslog_timestamp" => "Dec  2 03:17:06",
          "syslog_hostname" => "hostname",
          "syslog_tag" => "tag",
          "cef_version" => "0",
          "cef_device_vendor" => "Vendor",
          "cef_device_product" => "Product",
          "cef_device_version" => "Version",
          "cef_device_event_class_id" => "ID",
          "cef_name" => "Name",
          "cef_severity" => "Severity",
          "foo" => "bar" }]}
    end
    context "text is syslog format and CEF (there is only one valid key in the CEF Extension field), Strict mode on, timestamp is rfc3339" do
      let (:config) {%[
        syslog_timestamp_format  \\d{4}-{,1}\\d{2}-{,1}\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+){,1}(?:\\Z|\\+\\d{2}:\\d{2})
      ]}
      let (:text) { "2014-06-07T18:55:09.019283+09:00 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|foo=bar" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        @timestamp = Time.parse("2014-06-07T18:55:09.019283+09:00").to_i
        @test_driver = create_driver(config)
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to eq [
        @timestamp, {
          "syslog_timestamp" => "2014-06-07T18:55:09.019283+09:00",
          "syslog_hostname" => "hostname",
          "syslog_tag" => "tag",
          "cef_version" => "0",
          "cef_device_vendor" => "Vendor",
          "cef_device_product" => "Product",
          "cef_device_version" => "Version",
          "cef_device_event_class_id" => "ID",
          "cef_name" => "Name",
          "cef_severity" => "Severity" }]}
    end
    context "timestamp is rfc3339, UTC+3" do
      let (:config) {%[
        syslog_timestamp_format  \\d{4}-{,1}\\d{2}-{,1}\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+){,1}(?:\\Z|\\+\\d{2}:\\d{2})
      ]}
      let (:text) { "2014-06-07T18:55:09.019283+03:00 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|foo=bar" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        @timestamp = Time.parse("2014-06-07T18:55:09.019283+03:00").to_i
        @test_driver = create_driver(config)
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to eq [
        @timestamp, {
          "syslog_timestamp" => "2014-06-07T18:55:09.019283+03:00",
          "syslog_hostname" => "hostname",
          "syslog_tag" => "tag",
          "cef_version" => "0",
          "cef_device_vendor" => "Vendor",
          "cef_device_product" => "Product",
          "cef_device_version" => "Version",
          "cef_device_event_class_id" => "ID",
          "cef_name" => "Name",
          "cef_severity" => "Severity" }]}
    end
    context "timestamp is rfc3339, UTC+0" do
      let (:config) {%[
        syslog_timestamp_format  \\d{4}-{,1}\\d{2}-{,1}\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+){,1}(?:Z|\\+\\d{2}:\\d{2})
      ]}
      let (:text) { "2014-06-07T18:55:09.019283Z hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|foo=bar" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        @timestamp = Time.parse("2014-06-07T18:55:09.019283Z").to_i
        @test_driver = create_driver(config)
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to eq [
        @timestamp, {
          "syslog_timestamp" => "2014-06-07T18:55:09.019283Z",
          "syslog_hostname" => "hostname",
          "syslog_tag" => "tag",
          "cef_version" => "0",
          "cef_device_vendor" => "Vendor",
          "cef_device_product" => "Product",
          "cef_device_version" => "Version",
          "cef_device_event_class_id" => "ID",
          "cef_name" => "Name",
          "cef_severity" => "Severity" }]}
    end
    context "utc offset set to +04:00" do
      let (:config) {%[
        log_utc_offset  +04:00
      ]}
      let (:text) { "Dec  2 03:17:06 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|cs1=test" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        @timestamp = Time.parse("Dec  2 03:17:06 +04:00").to_i
        @test_driver = create_driver(config)
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to eq [
        @timestamp, {
          "syslog_timestamp" => "Dec  2 03:17:06",
          "syslog_hostname" => "hostname",
          "syslog_tag" => "tag",
          "cef_version" => "0",
          "cef_device_vendor" => "Vendor",
          "cef_device_product" => "Product",
          "cef_device_version" => "Version",
          "cef_device_event_class_id" => "ID",
          "cef_name" => "Name",
          "cef_severity" => "Severity",
          "cs1" => "test" }]}
    end
    context "utc offset set to -11:00, but log timestamp has timezone information, so utc offset is ignored" do
      let (:config) {%[
        syslog_timestamp_format  \\d{4}-{,1}\\d{2}-{,1}\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+){,1}(?:\\Z|\\+\\d{2}:\\d{2})
        log_utc_offset  -11:00
      ]}
      let (:text) { "2013-07-24T12:34:56.923984+03:30 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|cs1=test" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        @timestamp = Time.parse("2013-07-24T12:34:56.923984+03:30").to_i
        @test_driver = create_driver(config)
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to eq [
        @timestamp, {
          "syslog_timestamp" => "2013-07-24T12:34:56.923984+03:30",
          "syslog_hostname" => "hostname",
          "syslog_tag" => "tag",
          "cef_version" => "0",
          "cef_device_vendor" => "Vendor",
          "cef_device_product" => "Product",
          "cef_device_version" => "Version",
          "cef_device_event_class_id" => "ID",
          "cef_name" => "Name",
          "cef_severity" => "Severity",
          "cs1" => "test" }]}
    end
    context "syslog message is UTF-8, with BOM" do
      let (:config) {%[
        log_utc_offset  -07:00
      ]}
      let (:text) { "Dec  2 03:17:06 hostname tag ***CEF:0|Vendor|Product|Version|ID|Name|Severity|cs1=test" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        @timestamp = Time.parse("Dec  2 03:17:06 -07:00").to_i
        @test_driver = create_driver(config)
        text.setbyte(29, 0xef)
        text.setbyte(30, 0xbb)
        text.setbyte(31, 0xbf)
        text.force_encoding("ascii-8bit")
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to eq [
        @timestamp, {
          "syslog_timestamp" => "Dec  2 03:17:06",
          "syslog_hostname" => "hostname",
          "syslog_tag" => "tag",
          "cef_version" => "0",
          "cef_device_vendor" => "Vendor",
          "cef_device_product" => "Product",
          "cef_device_version" => "Version",
          "cef_device_event_class_id" => "ID",
          "cef_name" => "Name",
          "cef_severity" => "Severity",
          "cs1" => "test" }]}
    end
    context "syslog message is UTF-8, but including invalid UTF-8 string" do
      let (:config) {%[
        log_utc_offset  +09:00
      ]}
      let (:text) { "Feb 19 00:35:11 hogehuga CEF:0|Vendor|Product|Version|ID|Name|Severity|src=192.168.1.1 spt=60000 dst=172.16.100.100 dpt=80 msg=\xe3\x2e\x2e\x2e" }
      subject do
        allow(Fluent::Engine).to receive(:now).and_return(Fluent::EventTime.now)
        @timestamp = Time.parse("Feb 19 00:35:11 +09:00").to_i
        @test_driver = create_driver(config)
        parsed = nil
        @test_driver.instance.parse(text) do |time, record|
          parsed = [time, record]
        end
        parsed
      end
      it { is_expected.to eq [
        @timestamp, {
          "syslog_timestamp" => "Feb 19 00:35:11",
          "syslog_hostname" => "hogehuga",
          "syslog_tag" => "",
          "cef_version" => "0",
          "cef_device_vendor" => "Vendor",
          "cef_device_product" => "Product",
          "cef_device_version" => "Version",
          "cef_device_event_class_id" => "ID",
          "cef_name" => "Name",
          "cef_severity" => "Severity",
          "src" => "192.168.1.1",
          "spt" => "60000",
          "dst" => "172.16.100.100",
          "dpt" => "80",
          "msg" => "\xe3\x2e\x2e\x2e".scrub('?') }]}
    end
  end
end
