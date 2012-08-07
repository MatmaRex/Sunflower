# coding: utf-8
require 'rest-client'
require 'json'
require 'cgi'

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
	VERSION = '0.4.5'
	
	INVALID_CHARS = %w(# < > [ ] | { })
	INVALID_CHARS_REGEX = Regexp.union *INVALID_CHARS
	
	# Path to user data file.
	def self.path
		File.join(ENV['HOME'], 'sunflower-userdata')
	end

	# Summary used when saving edits with this Sunflower.
	attr_accessor :summary
	# Whether to run #code_cleanup when calling #save.
	attr_accessor :always_do_code_cleanup
	# The URL this Sunflower works on, as provided as argument to #initialize.
	attr_reader :wikiURL
	# Siteinfo, as returned by API call.
	attr_accessor :siteinfo
	
	# Whether this user (if logged in) has bot rights.
	def is_bot?; @is_bot; end
	
	# Whether to output warning messages (using Kernel#warn). Defaults to true.
	attr_writer :warnings
	def warnings?; @warnings; end
	
	# Whether to output log messages (to a file named log.txt in current directory). Defaults to false.
	attr_writer :log
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
				raise Sunflower::Error, 'initialize: no URL supplied and no userdata found!'
			end
		end
		
		@warnings=true
		@log=false
		
		@wikiURL=url
		
		@loggedin=false
		
		siprop = 'general|namespaces|namespacealiases|specialpagealiases|magicwords|interwikimap|dbrepllag|statistics|usergroups|extensions|fileextensions|rightsinfo|languages|skins|extensiontags|functionhooks|showhooks|variables'
		@siteinfo = self.API(action: 'query', meta: 'siteinfo', siprop: siprop)['query']
		
		_build_ns_map
	end
	
	# Private. Massages data from siteinfo to be used for recognizing namespaces.
	def _build_ns_map
		@namespace_to_id = {} # all keys lowercase
		@namespace_id_to_canon = {}
		@namespace_id_to_local = {}
		
		@siteinfo['namespaces'].each_value do |h|
			next if h['content']
			
			id = h['id'].to_i
			@namespace_id_to_canon[id] = h['canonical']
			@namespace_id_to_local[id] = h['*']
			
			@namespace_to_id[ h['canonical'].downcase ] = id
			@namespace_to_id[ h['*'].downcase ] = id
		end
		@siteinfo['namespacealiases'].each do |h|
			@namespace_to_id[ h['*'].downcase ] = h['id'].to_i
		end
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
	
	# Call the API. While more results are available via the xxcontinue parameter, call it again. 
	# 
	# Assumes action=query. 
	# 
	# By default returns an array of all API responses. Attempts to merge the responses
	# into a response that would have been returned if the limit was infinite. merge_on is
	# the key of response['query'] to merge consecutive responses on.
	# 
	# If limit given, will perform no more than this many API calls before returning.
	# If limit is 1, behaves exactly like #API.
	# 
	# Example: get list of all pages linking to Main Page:
	#   
	#   sunflower.API_continued "action=query&list=backlinks&bllimit=max&bltitle=Main_Page", 'backlinks', 'blcontinue'
	def API_continued request, merge_on, xxcontinue, limit=nil
		out = []
		
		# gather
		res = self.API(request)
		out << res
		while res['query-continue'] and (!limit || out.length < limit)
			api_endpoint = if request.is_a? String
				request + "&#{xxcontinue}=#{res["query-continue"][merge_on][xxcontinue]}"
			elsif request.is_a? Hash
				request.merge({xxcontinue => res["query-continue"][merge_on][xxcontinue]})
			end
			
			res = self.API(api_endpoint)
			out << res
		end
		
		# merge
		merged = out[0]
		meth = (merged['query'][merge_on].is_a?(Hash) ? :merge! : :concat)
		
		out.drop(1).each do |cur|
			merged['query'][merge_on].send meth, cur['query'][merge_on]
		end
		
		return merged
	end
	
	# Log in using given info.
	def login user='', password=''
		if user=='' || password==''
			if !@userdata.empty?
				user=@userdata[1] if user==''
				password=@userdata[2] if password==''
			else
				raise Sunflower::Error, 'login: no user/pass supplied and no userdata found!'
			end
		end
		
		raise Sunflower::Error, 'bad username!' if user =~ INVALID_CHARS_REGEX
		
		
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
		
		
		raise Sunflower::Error, 'unable to log in (no cookies received)!' if !@cookies
		
		
		# 3. confirm you did log in by checking the watchlist.
		@loggedin=true
		r=self.API('action=query&list=watchlistraw')
		if r['error'] && r['error']['code']=='wrnotloggedin'
			@loggedin=false
			raise Sunflower::Error, 'unable to log in!'
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
	
	# Log message to a file named log.txt in current directory, if logging is enabled. See #log= / #log?.
	def log message
		File.open('log.txt','a'){|f| f.puts message} if @log
	end
	
	# Cleans up underscores, percent-encoding and title-casing in title (with optional anchor).
	def cleanup_title title
		name, anchor = title.split '#', 2
		
		# CGI.unescape also changes pluses to spaces; code borrowed from there
		unescape = lambda{|a| a.gsub(/((?:%[0-9a-fA-F]{2})+)/){ [$1.delete('%')].pack('H*') } }
		
		ns = nil
		name = unescape.call(name).gsub(/[ _]+/, ' ').strip
		anchor = unescape.call(anchor.gsub(/\.([0-9a-fA-F]{2})/, '%\1')).gsub(/[ _]+/, ' ').strip if anchor
		
		# FIXME unicode? downcase, upcase
		
		if name.include? ':'
			maybe_ns, part_name = name.split ':', 2
			if ns_id = @namespace_to_id[maybe_ns.strip.downcase]
				ns, name = @namespace_id_to_local[ns_id], part_name.strip
			end
		end
		
		name[0] = name[0].upcase if @siteinfo["general"]["case"] == "first-letter"
		
		return [ns ? "#{ns}:" : nil,  name,  anchor ? "##{anchor}" : nil].join ''
	end
	
	# Returns the localized namespace name for ns, which may be namespace number, canonical name, or any namespace alias.
	# 
	# Returns nil if passed an invalid namespace.
	def ns_local_for ns
		case ns
		when Numeric
			@namespace_id_to_local[ns.to_i]
		when String
			@namespace_id_to_local[ @namespace_to_id[cleanup_title(ns).downcase] ]
		end
	end
	
	# Like #ns_local_for, but returns canonical (English) name.
	def ns_canon_for ns
		case ns
		when Numeric
			@namespace_id_to_canon[ns.to_i]
		when String
			@namespace_id_to_canon[ @namespace_to_id[cleanup_title(ns).downcase] ]
		end
	end
	
	# Returns a regular expression that will match given namespace. Rules for input like #ns_local_for.
	# 
	# Does NOT handle percent-encoding and underscores. Use #cleanup_title to canonicalize the namespace first.
	def ns_regex_for ns
		id = ns.is_a?(Numeric) ? ns.to_i : @namespace_to_id[cleanup_title(ns).downcase]
		return nil if !id
		
		/#{@namespace_to_id.to_a.select{|a| a[1] == id }.map{|a| Regexp.escape a[0] }.join '|' }/i
	end
end

# Class representing a single Wiki page. To load specified page, use #new. To save it back, use #save.
class Sunflower::Page
	# Characters which MediaWiki does not permit in page title.
	INVALID_CHARS = %w(# < > [ ] | { })
	# Regex matching characters which MediaWiki does not permit in page title.
	INVALID_CHARS_REGEX = Regexp.union *INVALID_CHARS
	
	# The current text of the page.
	attr_accessor :text
	# The text of the page, as of when it was loaded.
	attr_reader :orig_text
	
	# The Sunflower instance this page belongs to.
	attr_reader :sunflower
	
	# this is only for RDoc. wrapped in "if false" to avoid warnings when running with ruby -w
	if false
	# Return value of given attribute, as returned by API call prop=info for this page. Lazy-loaded.
	attr_reader :pageid, :ns, :title, :touched, :lastrevid, :counter, :length, :starttimestamp, :edittoken, :protection
	end
	
	# calling any of these accessors will fetch the data.
	[:pageid, :ns, :title, :touched, :lastrevid, :counter, :length, :starttimestamp, :edittoken, :protection].each do |meth|
		define_method meth do
			preload_attrs unless @preloaded_attrs
			instance_variable_get "@#{meth}"
		end
	end
	
	# Load the specified page. Only the text will be immediately loaded - attributes and edit token will be loaded when needed, or when you call #preload_attrs.
	#
	# If you are using multiple Sunflowers, you have to specify which wiki this page belongs to using the second argument of function; you can pass whole URL (same as when creating new Sunflower) or just the language code.
	def initialize title='', wiki=''
		raise Sunflower::Error, 'title invalid: '+title if title =~ INVALID_CHARS_REGEX
		
		@modulesExecd=[] #used by sunflower-commontasks.rb
		@summaryAppend=[] #used by sunflower-commontasks.rb
		
		wiki = wiki+'.wikipedia.org' if wiki.index('.')==nil && wiki!=''
		
		if wiki=='' 
			count=ObjectSpace.each_object(Sunflower){|o| @sunflower=o}
			raise Sunflower::Error, 'no Sunflowers present' if count==0
			raise Sunflower::Error, 'you must pass wiki name if using multiple Sunflowers at once' if count>1
		else
			ObjectSpace.each_object(Sunflower){|o| @sunflower=o if o.wikiURL==wiki}
		end
		
		raise Sunflower::Error, "no Sunflower for #{wiki}" if !@sunflower
		
		@title = @sunflower.cleanup_title title
		
		if title==''
			@text=''
			@orig_text=''
			return
		end
		
		preload_text
	end
	
	# Load the text of this page. Semi-private.
	def preload_text
		r = @sunflower.API('action=query&prop=revisions&rvprop=content&titles='+CGI.escape(@title))
		r = r['query']['pages'].values.first
		if r['missing']
			@text = ''
		elsif r['invalid']
			raise Sunflower::Error, 'title invalid: '+@title
		else
			@text = r['revisions'][0]['*']
		end
		
		@orig_text = @text.dup
		
		@preloaded_text = true
	end
	
	# Load the metadata associated with this page. Semi-private.
	def preload_attrs
		r = @sunflower.API('action=query&prop=info&inprop=protection&intoken=edit&titles='+CGI.escape(@title))
		r = r['query']['pages'].values.first
		r.each{|key, value|
			self.instance_variable_set('@'+key, value)
		}
		
		@preloaded_attrs = true
	end
	
	# Save the current text of this page to file (which can be either a filename or an IO).
	def dump_to file
		if file.respond_to? :write #probably file or IO
			file.write @text
		else #filename?
			File.open(file.to_s, 'w'){|f| f.write @text}
		end
	end
	
	# Save the current text of this page to a file whose name is based on page title, with non-alphanumeric characters stripped.
	def dump
		self.dump_to @title.gsub(/[^a-zA-Z0-9\-]/,'_')+'.txt'
	end
	
	# Save the modifications to this page, possibly under a different title. Default summary is this page's Sunflower's summary (see Sunflower#summary=). Default title is the current title.
	# 
	# Will not perform API request if no changes were made.
	# 
	# Will call #code_cleanup if Sunflower#always_do_code_cleanup is set.
	# 
	# Returns the JSON result of API call or nil when API call was not made.
	def save title=@title, summary=nil
		preload_attrs unless @preloaded_attrs
		
		summary = @sunflower.summary if !summary
		
		raise Sunflower::Error, 'title invalid: '+title if title =~ INVALID_CHARS_REGEX
		raise Sunflower::Error, 'no summary!' if (!summary or summary=='') && @summaryAppend.empty?
		
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
		self.new(title, wiki)
	end
	
	def self.load title, wiki=''
		self.new(title, wiki)
	end
end

# For backwards compatibility. Deprecated.
class Page # :nodoc:
	class << self
		def new *a
			warn "warning: toplevel Page class has been renamed to Sunflower::Page, this alias will be removed in future versions"
			Sunflower::Page.new *a
		end
		alias get new
		alias load new
	end
end

# For backwards compatibility. Deprecated.
# 
# We use inheritance shenanigans to keep the usage in "begin ... rescue ... end" working.
class SunflowerError < StandardError # :nodoc:
	%w[== backtrace exception inspect message set_backtrace to_s].each do |meth|
		define_method meth.to_sym do |*a, &b|
			if self.class == Sunflower::Error and !@warned
				warn "warning: toplevel SunflowerError class has been renamed to Sunflower::Error, this alias will be removed in future versions"
				@warned = true
			end
			
			super *a, &b
		end
	end
	
	class << self
		def new *a
			warn "warning: toplevel SunflowerError class has been renamed to Sunflower::Error, this alias will be removed in future versions" unless self == Sunflower::Error
			super
		end
		def exception *a
			warn "warning: toplevel SunflowerError class has been renamed to Sunflower::Error, this alias will be removed in future versions" unless self == Sunflower::Error
			super
		end
	end
end


# Represents an error raised by Sunflower.
class Sunflower::Error < SunflowerError; end
