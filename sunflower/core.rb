require 'net/http'
require 'net/https'
require 'json'
require 'cgi'
include Net

class Sunflower
=begin

Main class. To start working, you have to create new Sunflower:
	s=Sunflower.new('en.wikipedia.org')
And then log in:
	s.login('Username','password')

Then you can request data from API using #API method.
To log data to file, use #log method (works like puts, append new line if needed) of #log2 (like print).
You can use multiple Sunflowers at once, to work on multiple wikis.
=end

	attr_accessor :cookie, :headers, :wikiURL, :warnings, :log
	
	def initialize(url='') #pl.wikipedia.org
		begin
			f=File.open('userdata')
			r=f.read
			f.close
			@userdata=r.split(/\r?\n/).map{|i| i.strip}
		rescue
			@userdata=[]
		end
		
		if url==''
			if !@userdata.empty?
				url=@userdata[0]
			else
				raise RuntimeError, 'Sunflower - initialize: no URL supplied and no userdata found!'
			end
		end
		
		@warnings=true
		@log=true
		
		@wikiURL=url
		@logData=''
		
		@loggedin=false
		@cookie=''
		@headers = {
			'User-Agent' => 'Sunflower alpha',
			'Cookie' => @cookie
		}
	end
	
	def API(request)
		$stderr.puts 'Warning: Sunflower: API request before logging in! ('+request+')' unless @loggedin || !@warnings
		self.log 'http://'+@wikiURL+'/w/api.php?'+request+'&format=jsonfm'
		http=HTTP.start(@wikiURL)
		resp=http.request(HTTP::Post.new('/w/api.php', @headers), request+'&format=json')
		JSON.parse(resp.body.to_s)
	end
	
	def login(user='', password='', donotsave=false)
		if user=='' || password==''
			if !@userdata.empty?
				user=@userdata[1] if user==''
				password=@userdata[2] if password==''
			else
				raise RuntimeError, 'Sunflower - login: no user/pass supplied and no userdata found!'
			end
		end
		
		if user.index(/[#<>\[\]\|\{\}]/)
			raise RuntimeError, 'Sunflower - bad username!'
		end
		
		http=HTTP.start(@wikiURL)
		
		resp=http.request(HTTP::Post.new('/w/api.php', @headers), "action=login&lgname=#{user}&lgpassword=#{password}")
		@headers['Cookie'] = @cookie = resp.response['set-cookie']
		
		raise RuntimeError, 'Sunflower - unable to log in (no cookies received)!' if !@cookie
		
		
		@loggedin=true		
		r=self.API('action=query&list=watchlistraw')
		if r['error'] && r['error']['code']=='wrnotloggedin'
			@loggedin=false
			raise RuntimeError, 'Sunflower - unable to log in!'
		end
		
		r=self.API('action=query&list=allusers&aulimit=1&augroup=bot&aufrom='+user)
		unless r['query']['allusers'][0]['name']==user
			$stderr.puts 'Warning: Sunflower - this user does not have bot rights!' if @warnings
			@haveBotRights=false
		else
			@haveBotRights=true
		end
	end
	
	def log2(t)
		@logData+=t
		if @log
			f=File.open('log.txt','a')
			f.write t
			f.close
		end
	end
	
	def log(t)
		self.log2(t.to_s.chomp+"\n")
	end
	
	def isBot?
		@haveBotRights
	end
end

class Page
=begin
Class representng single Wiki page. To load specified page, use #new/#get/#load method.

If you are using multiple Sunflowers, you have to specify which wiki this page belongs to using second argument of function; you can pass whole URL (same as when creating new Sunflower) or just language code.

To read page text, use #text or #read method.
To change text of page, use #text= or #write method.

To save page, use #save/#put method. Optional argument is new title page, if ommited, page is saved at old title. Summary can be passed as second parameter. If it's ommited, global variable $summary is used. If it's empty too, error is raised.

To get Sunflower instance which this page belongs to, use #sunflower of #belongs_to.
=end

	attr_accessor :text
	alias :read :text
	alias :write :text=
	
	attr_reader :orig_text
	alias :origText :orig_text
	
	attr_reader :sunflower
	alias :belongs_to :sunflower
	
	attr_reader :pageid, :ns, :title, :touched, :lastrevid, :counter, :length, :starttimestamp, :edittoken, :protection #prop=info
	
	def initialize(title='', wiki='')
		raise RuntimeError, 'Sunflower - title invalid: '+title if title.index(/[#<>\[\]\|\{\}]/)
		
		@modulesExecd=[] #used by sunflower-commontasks.rb
		@summaryAppend=[] #used by sunflower-commontasks.rb
		
		@title=title
		wiki=wiki+'.wikipedia.org' if wiki.index('.')==nil && wiki!=''
		
		if wiki=='' 
			count=ObjectSpace.each_object(Sunflower){|o| @sunflower=o}
			raise RuntimeError, 'Sunflower - you must pass wiki name if using multiple Sunflowers at once!' if count>1
		else
			ObjectSpace.each_object(Sunflower){|o| @sunflower=o if o.wikiURL==wiki}
		end
		
		if title==''
			@text=''
			@orig_text=''
			return
		end
		
		r=@sunflower.API('action=query&prop=info&inprop=protection&intoken=edit&titles='+CGI.escape(@title))
		r=r['query']['pages'][r['query']['pages'].keys[0] ]
		r.each{|key,value|
			self.instance_variable_set('@'+key, value)
		}
		
		r=@sunflower.API('action=query&prop=revisions&rvprop=content&titles='+CGI.escape(@title))
		
		begin
			@text=r['query']['pages'][@pageid.to_s]['revisions'][0]['*']
		rescue Exception
			@text=''
		end
		@orig_text=@text
	end
	
	def dumpto(file)
		if file.respond_to? :write #probably file or IO
			file.write @text
		else #filename?
			f=File.open(file.to_s, 'w')
			f.write @text
			f.close
		end
	end
	
	def dump
		self.dumpto @title.gsub(/[^a-zA-Z0-9\-]/,'_')+'.txt'
	end
	
	def save(title=@title, summary=$summary)
		raise RuntimeError, 'Sunflower - title invalid: '+title if title.index(/[#<>\[\]\|\{\}]/)
		raise RuntimeError, 'Sunflower - no summary!' if (summary==nil || summary=='') && @summaryAppend==[]
		
		summary='' if summary==nil
		for i in @summaryAppend.uniq
			summary+=', '+i
		end
		summary.sub!(/^, /,'')
		
		
		if @orig_text==@text && title==@title
			@sunflower.log('Page '+title+' not saved - no changes.')
			return
		end
		
		
		
		self.code_cleanup if $alwaysDoCodeCleanup && self.respond_to?('code_cleanup')
		
		r=@sunflower.API("action=edit&bot=1&title=#{CGI.escape(title)}&text=#{CGI.escape(@text)}&summary=#{CGI.escape(summary)}&token=#{CGI.escape(@edittoken)}") if @sunflower.isBot?
	end
	alias :put :save
	
	def self.get(title, wiki='')
		Page.new(title, wiki)
	end
	
	def self.load(title, wiki='')
		Page.new(title, wiki)
	end
end

class Hash
# just a lil patch
	def first
		self.values[0]
	end
end