require 'stringio'
s = StringIO.new
s << <<-OUTPUT

'foo'

OUTPUT


s << <<-OUTPUT

'foobar'

OUTPUT

puts s.string

