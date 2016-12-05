# fluent-plugin-parser_cef

[![Gem Version](https://badge.fury.io/rb/fluent-plugin-parser_cef.svg)](https://badge.fury.io/rb/fluent-plugin-parser_cef)
[![Build Status](https://travis-ci.org/lunardial/fluent-plugin-parser_cef.svg?branch=master)](https://travis-ci.org/lunardial/fluent-plugin-parser_cef)
[![Code Climate](https://codeclimate.com/github/lunardial/fluent-plugin-parser_cef/badges/gpa.svg)](https://codeclimate.com/github/lunardial/fluent-plugin-parser_cef)
[![Issue Count](https://codeclimate.com/github/lunardial/fluent-plugin-parser_cef/badges/issue_count.svg)](https://codeclimate.com/github/lunardial/fluent-plugin-parser_cef)
[![downloads](https://img.shields.io/gem/dt/fluent-plugin-parser_cef.svg)](https://rubygems.org/gems/fluent-plugin-parser_cef)
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

Fluentd Parser plugin to parse CEF - common event format -

## Installation

Add this line to your application's Gemfile:

```bash
# for fluentd
gem install fluent-plugin-parser_cef

# for td-agent2
td-agent-gem install fluent-plugin-parser_cef
```

## Usage

```
<source>
  @type   tail
  tag     develop.cef
  path      /tmp/fluentd/test.log
  pos_file  /tmp/fluentd/test.pos

  format  cef
  #log_format  syslog
  #syslog_timestamp_format  '\w{3}\s+\d{1,2}\s\d{2}:\d{2}:\d{2}'
  #cef_version  0
  #parse_strict_mode  true
  #cef_keyfilename  'config/cef_version_0_keys.yaml'
  #output_raw_field  false
</source>
```

## parameters

* `log_format` (default: syslog)

  input log format, currently only 'syslog' is valid

* `syslog_timestamp` (default: '\w{3}\s+\d{1,2}\s\d{2}:\d{2}:\d{2}')

  syslog timestamp format, the default is traditional syslog timestamp

* `cef_version` (default: 0)

  CEF version, this should be 0

* `parse_strict_mode` (default: true)

  if the CEF extensions are the following, the value of the key cs2 should 'foo hoge=fuga'

  - cs1=test cs2=foo hoge=fuga cs3=bar

  if parse_strict_mode is false, this is raugh parse, so the value of the key cs2 become 'foo' and non CEF key 'hoge' shown, and the value is 'fuga'

* `cef_keyfilename` (default: 'config/cef_version_0_keys.yaml')

  used when parse_strict_mode is true, this is the array of the valid CEF keys

* `output_raw_field` (default: false)

  append {"raw":\<message itself\>} key-value even if success parsing

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
