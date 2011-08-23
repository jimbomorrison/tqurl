module Tqurl
  module VERSION
    MAJOR  = '0' unless defined? MAJOR
    MINOR  = '6' unless defined? MINOR
    TINY   = '3' unless defined? TINY
    BETA   = nil unless defined? BETA # Time.now.to_i.to_s
  end

  Version = [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY, VERSION::BETA].compact * '.'
end
