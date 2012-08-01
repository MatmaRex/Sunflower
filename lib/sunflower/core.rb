# coding: utf-8
require 'rest-client'
require 'json'
require 'cgi'

class SunflowerError < StandardError; end

# Main class. To start working, you have to create new Sunflower:
#   s = Sunflower.new('en.wikipedia.org')
# And then log in:
#   s.login('Username','password')
#
# If you have ran setup, you can just use
#   s = Sunflower.new.login
#
# Then you can request data from API using #API method.
#
# To log data to file, use #log method (works like puts). Use RestClient.log=<io> to log all requests.
#
# You can use multiple Sunflowers at once, to work on multiple wikis.
class Sunflower
	VERSION = '0.4.3'
	
	INVALID_CHARS = %w(# < > [ ] | { })
	INVALID_CHARS_REGEX = Regexp.union *INVALID_CHARS
	
	# Path to user data file.
	def self.path
		File.join(ENV['HOME'], 'sunflower-userdata')
	end

	# Options for this Sunflower.
	attr_accessor :summary, :always_do_code_cleanup
	attr_accessor :cookie, :headers, :wikiURL
	
	def is_bot?; @is_bot; end
	
	attr_writer :warnings, :log
	def warnings?; @warnings; end
	def log?; @log; end
	
	# Initialize a new Sunflower working on a wiki with given URL, for ex. "pl.wikipedia.org".
	def initialize url=nil
		begin
			r=File.read(Sunflower.path)
			@userdata=r.split(/\r?\n/).map{|i| i.strip}
		rescue
			@userdata=[]
		end
		
		if !url
			if !@userdata.empty?
				url=@userdata[0]
			else
				raise SunflowerError, 'initialize: no URL supplied and no userdata found!'
			end
		end
		
		@warnings=true
		@log=false
		
		@wikiURL=url
		
		@loggedin=false
	end
	
	# Call the API. Returns a hash of JSON response. Request can be a HTTP request string or a hash.
	def API request
		if request.is_a? String
			request += '&format=json'
		elsif request.is_a? Hash
			request = request.merge({format:'json'})
		end
		
		resp = RestClient.post(
			'http://'+@wikiURL+'/w/api.php',
			request,
			{:user_agent => "Sunflower #{VERSION} alpha", :cookies => @cookies}
		)
		JSON.parse resp.to_str
	end
	
	# Log in using given info.
	def login user='', password=''
		if user=='' || password==''
			if !@userdata.empty?
				user=@userdata[1] if user==''
				password=@userdata[2] if password==''
			else
				raise SunflowerError, 'login: no user/pass supplied and no userdata found!'
			end
		end
		
		raise SunflowerError, 'bad username!' if user =~ INVALID_CHARS_REGEX
		
		
		# 1. get the login token
		response = RestClient.post(
			'http://'+@wikiURL+'/w/api.php?'+"action=login&lgname=#{CGI.escape user}&lgpassword=#{CGI.escape password}"+'&format=json', 
			nil,
			{:user_agent => 'Sunflower alpha'}
		)
		
		@cookies = response.cookies
		json = JSON.parse response.to_str
		token, prefix = json['login']['token'], json['login']['cookieprefix']
		
		
		# 2. actually log in
		response = RestClient.post(
			'http://'+@wikiURL+'/w/api.php?'+"action=login&lgname=#{CGI.escape user}&lgpassword=#{CGI.escape password}&lgtoken=#{token}"+'&format=json',
			nil,
			{:user_agent => 'Sunflower alpha', :cookies => @cookies}
		)
		
		json = JSON.parse response.to_str
		
		@cookies = @cookies.merge(response.cookies).merge({
			"#{prefix}UserName" => json['login']['lgusername'].to_s,
			"#{prefix}UserID" => json['login']['lguserid'].to_s,
			"#{prefix}Token" => json['login']['lgtoken'].to_s
		})
		
		
		raise SunflowerError, 'unable to log in (no cookies received)!' if !@cookies
		
		
		# 3. confirm you did log in by checking the watchlist.
		@loggedin=true
		r=self.API('action=query&list=watchlistraw')
		if r['error'] && r['error']['code']=='wrnotloggedin'
			@loggedin=false
			raise SunflowerError, 'unable to log in!'
		end
		
		# 4. check bot rights
		r=self.API('action=query&list=allusers&aulimit=1&augroup=bot&aufrom='+(CGI.escape user))
		unless r['query']['allusers'][0]['name']==user
			warn 'Sunflower - this user does not have bot rights!' if @warnings
			@is_bot=false
		else
			@is_bot=true
		end
		
		return self
	end
	
	def log t
		File.open('log.txt','a'){|f| f.puts t} if @log
	end
end

# Class representng single Wiki page. To load specified page, use #new/#get/#load method.
#
# When calling Page.new, at first only the text will be loaded - attributes and edit token will be loaded when needed, or when you call #preload_attrs.
#
# If you are using multiple Sunflowers, you have to specify which wiki this page belongs to using second argument of function; you can pass whole URL (same as when creating new Sunflower) or just language code.
#
# To save page, use #save/#put method. Optional argument is new title page, if ommited, page is saved at old title. Summary can be passed as second parameter. If it's ommited, s.summary is used. If it's empty too, error is raised.
#
# To get Sunflower instance which this page belongs to, use #sunflower of #belongs_to.
class Page
	INVALID_CHARS = %w(# < > [ ] | { })
	INVALID_CHARS_REGEX = Regexp.union *INVALID_CHARS
	
	attr_accessor :text
	attr_reader :orig_text
	
	attr_reader :sunflower
	alias :belongs_to :sunflower
	
	# this is only for RDoc. wrapped in "if false" to avoid warnings when running with ruby -w
	if false
	attr_reader :pageid, :ns, :title, :touched, :lastrevid, :counter, :length, :starttimestamp, :edittoken, :protection #prop=info
	end
	
	# calling any of these accessors will fetch the data.
	[:pageid, :ns, :title, :touched, :lastrevid, :counter, :length, :starttimestamp, :edittoken, :protection].each do |meth|
		define_method meth do
			preload_attrs unless @preloaded_attrs
			instance_variable_get "@#{meth}"
		end
	end
	
	def initialize title='', wiki=''
		raise SunflowerError, 'title invalid: '+title if title =~ INVALID_CHARS_REGEX
		
		@modulesExecd=[] #used by sunflower-commontasks.rb
		@summaryAppend=[] #used by sunflower-commontasks.rb
		
		@title=title
		wiki=wiki+'.wikipedia.org' if wiki.index('.')==nil && wiki!=''
		
		if wiki=='' 
			count=ObjectSpace.each_object(Sunflower){|o| @sunflower=o}
			raise SunflowerError, 'you must pass wiki name if using multiple Sunflowers at once!' if count>1
		else
			ObjectSpace.each_object(Sunflower){|o| @sunflower=o if o.wikiURL==wiki}
		end
		
		if title==''
			@text=''
			@orig_text=''
			return
		end
		
		preload_text
	end
	
	def preload_text
		r = @sunflower.API('action=query&prop=revisions&rvprop=content&titles='+CGI.escape(@title))
		r = r['query']['pages'].first
		if r['missing']
			@text = ''
		elsif r['invalid']
			raise SunflowerError, 'title invalid: '+@title
		else
			@text = r['revisions'][0]['*']
		end
		
		@orig_text = @text.dup
		
		@preloaded_text = true
	end
	
	def preload_attrs
		r = @sunflower.API('action=query&prop=info&inprop=protection&intoken=edit&titles='+CGI.escape(@title))
		r = r['query']['pages'].first
		r.each{|key, value|
			self.instance_variable_set('@'+key, value)
		}
		
		@preloaded_attrs = true
	end
	
	def dump_to file
		if file.respond_to? :write #probably file or IO
			file.write @text
		else #filename?
			File.open(file.to_s, 'w'){|f| f.write @text}
		end
	end
	
	def dump
		self.dump_to @title.gsub(/[^a-zA-Z0-9\-]/,'_')+'.txt'
	end
	
	def save title=@title, summary=nil
		preload_attrs unless @preloaded_attrs
		
		summary = @sunflower.summary if !summary
		
		raise SunflowerError, 'title invalid: '+title if title =~ INVALID_CHARS_REGEX
		raise SunflowerError, 'no summary!' if (!summary or summary=='') && @summaryAppend.empty?
		
		unless @summaryAppend.empty?
			if !summary or summary==''
				summary = @summaryAppend.uniq.join(', ')
			else
				summary = summary.sub(/,\s*\Z/, '') + ', ' + @summaryAppend.uniq.join(', ')
			end
		end
		
		if @orig_text==@text && title==@title
			@sunflower.log('Page '+title+' not saved - no changes.')
			return nil
		end
		
		
		self.code_cleanup if @sunflower.always_do_code_cleanup && self.respond_to?('code_cleanup')
		
		return @sunflower.API("action=edit&bot=1&title=#{CGI.escape(title)}&text=#{CGI.escape(@text)}&summary=#{CGI.escape(summary)}&token=#{CGI.escape(@edittoken)}")
	end
	alias :put :save
	
	def self.get title, wiki=''
		Page.new(title, wiki)
	end
	
	def self.load title, wiki=''
		Page.new(title, wiki)
	end
end

class Hash
	# just a lil patch
	def first
		self.values[0]
	end
end

