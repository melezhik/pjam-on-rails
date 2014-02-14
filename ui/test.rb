require 'diff/lcs'
require 'diff/lcs/htmldiff'
require 'stringio'

begin
  require 'text/format'
rescue LoadError
  Diff::LCS::HTMLDiff.can_expand_tabs = false
end


left = ['1','2','3']
right = ['5','7','7']

class StringIO
    def << (text)
        self.write("#{self.readlines}\n#{text}")
        self.rewind
    end
end


s = StringIO.new()

t = Diff::LCS::HTMLDiff.new(left, right, :output => s )
t.run



puts s.readlines










