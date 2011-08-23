require 'rubygems'
require 'oauth'
require 'optparse'
require 'ostruct'
require 'stringio'
require 'yaml'

library_files = Dir[File.join(File.dirname(__FILE__), "/tqurl/**/*.rb")].sort
library_files.each do |file|
  require file
end

module Tqurl
  @options ||= Options.new
  class << self
    attr_accessor :options
  end

  class Exception < ::Exception
  end
end
