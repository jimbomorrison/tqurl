$:.unshift File.dirname(__FILE__) + '/../lib'
require 'tqurl'
require 'test/unit'
require 'rr'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end

Tqurl::RCFile.directory = ENV['TMPDIR']

module Tqurl
  class Options
    class << self
      def test_exemplar
        options                 = new
        options.username        = 'exemplar_user_name'
        options.password        = 'secret'
        options.consumer_key    = '123456789'
        options.consumer_secret = '987654321'
        options.subcommands     = []
        options
      end
    end
  end

  class OAuthClient
    class << self
      def test_exemplar(overrides = {})
        options = Tqurl::Options.test_exemplar

        overrides.each do |attribute, value|
          options.send("#{attribute}=", value)
        end

        load_new_client_from_options(options)
      end
    end
  end
end
