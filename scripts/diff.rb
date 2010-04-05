#!/usr/bin/ruby

require 'algo-diff.rb'
require 'sunflower-core.rb'
require 'enumerator'

$stdout.sync=true

start=<<EOF
Content-type: text/html; charset=utf-8

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <meta http-equiv="Content-type" content="text/html; charset=utf-8">
  <meta name="Author" content="Matma Rex">
	<title>The Actual Authors</title>
</head>
<body>

<div id='msg'>Be patient, it may take a minute...</div>
EOF

print start.strip

cssClassColors=[]

def randomcolor
	'#'+rand(0xffffff).to_s(16).rjust(6, '0')
end

class Array
	attr_accessor :deleteme
end

class NilClass
	def each
	end
end

class StringWithMarks < String
	attr_reader :marks

	def initialize *args
		super *args
		@marks=[]
	end

	def insertat(index, text)
		s=self[0, index]
		e=self[index, length-index]
		
		"#{s}#{text}#{e}"
	end
	
	def insertat!(index, text)
		self[0, length]=self.insertat(index, text)
	end
	
	def addmark(index, color, length)
		@marks<<[index, color, length]
		return @marks.length-1
	end

	def removemark(id)
		@marks.delete(id)
	end
	
	def nudgemarks(length, index, type)
		if type==:-
			@marks.each do |m|
				if m[0]>=index # removed part starts after m's start
					if m[0]>index+length # m is all after removed part
						m[0]-=length # so move it back
					else # m[0]<=index+length - removed part starts in m
						m[2]-=length # so shorten m
					end
				else # m[0]<index - removed part starts before m's start
					if m[0]+m[2]<=index # m is all before removed part
						# do nothing
					else # m[0]+m[2]>index - removed part ends in m
						m[2]-=index+length-m[0] # shorten it
						m[0]=index # and nudge beginning to proper position
					end
				end
			end
		else
			@marks.each do |m|
				if m[0]>=index # added part starts after m's start
					if m[0]>index+length # m is all after added part
						m[0]+=length # so move it forward
					else # m[0]<=index+length - added part starts in m
						m[2]+=length # so lenghten it
					end
				else # m[0]<index - added part starts before m's start
					if m[0]+m[2]<=index # m is all before added part
						# do nothing
					else # m[0]+m[2]>index - added part ends in m
						m[0]+=length # so move it forward
					end
				end
			end
		end
		
		@marks.delete_if{|m| m[2]<1 || m[0]<0}
	end
	
	def outputmarks
		m=@marks.each_with_index{|e, i| e[3]=i} # add index info
		m=m.sort{|m1, m2| ((a=m1[0]<=>m2[0])==0 ? a=m2[2]<=>m1[2] : a) }
		addthem=[]
		
		m.reverse!
		m.each_cons 2 do |later, earlier|
			if earlier[0]+earlier[2]>later[0]
				addthem<<[ earlier[0], earlier[1], later[0]-earlier[0],              earlier[3] ]
				addthem<<[ later[0],   earlier[1], earlier[2]-(later[0]-earlier[0]), earlier[3] ]
				earlier.deleteme=true
			end
		end
		m.delete_if{|i| i.deleteme}
		m=m+addthem
		@marks=m=m.sort_by{|m| m[3]}
		
		inserts=[]
		@marks.each do |index, color, length|
			inserts[index]=[] if inserts[index]==nil
			inserts[index+length]=[] if inserts[index+length]==nil
			
			inserts[index].push '<span style="background:'+color+'">'
			inserts[index+length].send((index!=index+length ? 'unshift' : 'push'), '</span>')
		end
		
		s=self.clone
		realindex=0
		self.length.times do |fakeindex|
			inserts[fakeindex].each do |text|
				s.insertat!(realindex, text)
				realindex+=text.length
			end
			realindex+=1
		end
		
		
		# m.reverse_each do |index, color, length|
			# s.insertat!(index+length, '</span>')
			# s.insertat!(index, '<span style="background:'+color+'">')
		# end
		
		return s
	end
	
	def patch(diffs, color)
		r=self.clone
		
		adds=[]
		removes=[]
		
		diffs.each do |type, index, text|
			if type==:-
				removes<<[index, text]
			elsif type==:+
				adds<<[index, text]
			else
				raise 'Unknown diff type: '+type.to_s
			end
		end
		
		removes.reverse_each do |index, text|
			raise "Actual text not matching diff data when deleting - #{r[index, text.length]} vs #{text}" if r[index, text.length]!=text
			r[index, text.length]=''
			r.nudgemarks(text.length, index, :-)
		end
		
		adds.each do |index, text|
			r.insertat! index, text
			r.nudgemarks(text.length, index, :+)
			r.addmark index, color, text.length
		end
		
		return r
  end
end

s=Sunflower.new 'pl.wikipedia.org'
s.warnings=false
s.log=false

cgi=CGI.new

versions=s.API('action=query&prop=revisions&titles='+CGI.escape(cgi['title'])+'&rvlimit=500&rvprop=timestamp|user|content|comment&rvdir=newer')['query']['pages'].values[0]['revisions'].map do |r|
	[r['*'].clone, r['user'], r['timestamp'], r['comment']]
end

colors=%w[white red green blue yellow purple fuchsia navy teal aqua olive lime silver gray]
colors<<randomcolor while colors.length<=versions.length

i=0
versions.map! do |v|
	v[0]=v[0].gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
	v[4]=colors[i]
	i+=1
	v
end

str=StringWithMarks.new(versions[0][0])


(versions.length-1).times do |i|
	diff=versions[i][0].diff(versions[i+1][0])
	str=str.patch(diff, colors[i+1])
end

html=<<EOF
<div style='border:1px solid black;margin:5px;padding:5px;float:right;text-align:right'>
Legend:<br>
#{versions.map{|c| "<span style='background:#{c[4]}'>#{c[1]} at #{c[2]}, comment: #{c[3]} (#{c[4]})</span>"}.join "<br>\n"}
</div>

<div style='white-space:pre-wrap;font-family:monotype'>
#{str.outputmarks}
</div>

<script type="text/javascript">
document.getElementById('msg').style.display='none'
</script>

</body>
</html>
EOF

$stdout.puts html.strip
File.open('./../data.txt','w').puts str.marks.map{|m| m.join ', '}