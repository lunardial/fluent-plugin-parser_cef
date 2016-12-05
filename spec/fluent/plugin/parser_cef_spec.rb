#-*- coding: utf-8 -*-

require 'fluent/plugin/parser_cef'
require 'fluent/test'

RSpec.describe Fluent::TextParser::CommonEventFormatParser do

  DEFAULT_CONFIGURE = %[
    log_format  syslog
    syslog_timestamp_format  \\w{3}\\s+\\d{1,2}\\s\\d{2}:\\d{2}:\\d{2}
    cef_version  0
    parse_strict_mode  true
    cef_keyfilename  'config/cef_version_0_keys.yaml'
    output_raw_field  false
  ]
  def create_driver(conf=DEFAULT_CONFIGURE, tag='test')
    Fluent::Test::ParserTestDriver.new(Fluent::TextParser::CommonEventFormatParser, tag).configure(conf)
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
        @test_driver.parse(text)
      end
      it { is_expected.to eq [nil, nil] }
    end
    context "text is empty string" do
      let (:text) { "" }
      subject do
        @test_driver.parse(text)
      end
      it { is_expected.to eq [nil, nil] }
    end
    context "text is not syslog format nor CEF" do
      let (:text) { "December 12 10:00:00 hostname tag message" }
      subject do
        @test_driver.parse(text)
      end
      it { is_expected.to contain_exactly(be_an(Integer), {"raw"=>"December 12 10:00:00 hostname tag message"}) }
    end
    context "text is not in syslog format but is CEF" do
      let (:text) { "December 12 10:00:00 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|cs1=test" }
      subject do
        @test_driver.parse(text)
      end
      it { is_expected.to contain_exactly(be_an(Integer), {"raw"=>"December 12 10:00:00 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|cs1=test"}) }
    end
    context "text is syslog format but not CEF" do
      let (:text) { "Dec 12 10:11:12 hostname tag message" }
      subject do
        @test_driver.parse(text)
      end
      it { is_expected.to contain_exactly(be_an(Integer), {"raw"=>"Dec 12 10:11:12 hostname tag message"}) }
    end
    context "text is syslog format and CEF (CEF Extension field is empty)" do
      let (:text) { "Dec  2 03:17:06 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|" }
      subject do
        @test_driver.parse(text)
      end
      it { is_expected.to eq [
        1480616226,
        {"syslog_timestamp"=>"Dec  2 03:17:06",
         "syslog_hostname"=>"hostname",
         "syslog_tag"=>"tag",
         "cef_version"=>"0",
         "cef_device_vendor"=>"Vendor",
         "cef_device_product"=>"Product",
         "cef_device_version"=>"Version",
         "cef_device_event_class_id"=>"ID",
         "cef_name"=>"Name",
         "cef_severity"=>"Severity"}
      ]}
    end
    context "text is syslog format and CEF (there is only one valid key in the CEF Extension field), Strict mode on" do
      let (:text) { "Dec  2 03:17:06 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|cs1=test" }
      subject do
        @test_driver.parse(text)
      end
      it { is_expected.to eq [
        1480616226,
        {"syslog_timestamp"=>"Dec  2 03:17:06",
         "syslog_hostname"=>"hostname",
         "syslog_tag"=>"tag",
         "cef_version"=>"0",
         "cef_device_vendor"=>"Vendor",
         "cef_device_product"=>"Product",
         "cef_device_version"=>"Version",
         "cef_device_event_class_id"=>"ID",
         "cef_name"=>"Name",
         "cef_severity"=>"Severity",
         "cs1"=>"test"}
      ]}
    end
    context "text is syslog format and CEF (there is only one valid key in the CEF Extension field), Strict mode off" do
      let (:config) {%[
        parse_strict_mode  false
      ]}
      let (:text) { "Dec  2 03:17:06 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|foo=bar" }
      subject do
        @test_driver = create_driver(config)
        @test_driver.parse(text)
      end
      it { is_expected.to eq [
        1480616226,
        {"syslog_timestamp"=>"Dec  2 03:17:06",
         "syslog_hostname"=>"hostname",
         "syslog_tag"=>"tag",
         "cef_version"=>"0",
         "cef_device_vendor"=>"Vendor",
         "cef_device_product"=>"Product",
         "cef_device_version"=>"Version",
         "cef_device_event_class_id"=>"ID",
         "cef_name"=>"Name",
         "cef_severity"=>"Severity",
         "foo"=>"bar"}
      ]}
    end
    context "text is syslog format and CEF (there is only one valid key in the CEF Extension field), Strict mode on, timestamp is rfc3339" do
      let (:config) {%[
        syslog_timestamp_format  \\d{4}-{,1}\\d{2}-{,1}\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+){,1}(?:\\Z|\\+\\d{2}:\\d{2})
      ]}
      let (:text) { "2014-06-07T18:55:09.019283+09:00 hostname tag CEF:0|Vendor|Product|Version|ID|Name|Severity|foo=bar" }
      subject do
        @test_driver = create_driver(config)
        @test_driver.parse(text)
      end
      it { is_expected.to eq [
        1402134909,
        {"syslog_timestamp"=>"2014-06-07T18:55:09.019283+09:00",
         "syslog_hostname"=>"hostname",
         "syslog_tag"=>"tag",
         "cef_version"=>"0",
         "cef_device_vendor"=>"Vendor",
         "cef_device_product"=>"Product",
         "cef_device_version"=>"Version",
         "cef_device_event_class_id"=>"ID",
         "cef_name"=>"Name",
         "cef_severity"=>"Severity"}
      ]}
    end
  end
end
