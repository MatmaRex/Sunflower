# coding: utf-8
# extends Page with some methods letting easily perform common tasks

class Page
	def execute commands
	# executes methods on self
	# "commands" is array of arrays
	# page.execute([
		# [:replace, 'something', 'whatever'],
		# [:append, 'some things']
	# ])
	#        equals to
	# page.replace('something', 'whatever')
	# page.append('some things')
	
	# allowed modifiers:
	# r, required
	# oi:module, only-if:module
	# !oi:module, only-if-not:module
	# s:append to summary, summary:append to summary
		originalText = self.text.dup
	
		commands.each do |cmd|
			f=cmd.shift
			if f.class==Array
				methodName=f.shift
				modifiers=f.map{|i|
					i+=':' if !i.include? ':'
					i=i.split(':',-1)
					i[0]=i[0].downcase.gsub(/[^a-z!]/,'')
					
					i[0]='r' if i[0]=='required'
					i[0]='oi' if i[0]=='onlyif'
					i[0]='!oi' if i[0]=='onlyifnot'
					i[0]='s' if i[0]=='summary'
					
					type=i.shift
					i=i.join(':')
					
					[type,i]
				}
				modifiers=Hash[*(modifiers.flatten)]
			else
				methodName=f
				modifiers={}
			end
			
			if modifiers['oi']
				if !@modulesExecd.index(modifiers['oi'].strip)
					next #skip this command
				end
			end
			if modifiers['!oi']
				if @modulesExecd.index(modifiers['oi'].strip)
					next #skip this command
				end
			end
			
			oldText=self.text
			self.method(methodName).call(*cmd)
			newText=self.text
			
			@modulesExecd<<methodName if oldText!=newText
			
			if modifiers['s'] && oldText!=newText
				@summaryAppend<<modifiers['s'].strip
			end
			
			if modifiers['r'] && oldText==newText
				self.text = originalText
				break #reset text and stop executing commands
			end
		end
	end
	
	
	
	def replace from, to, once=false
	# replaces "from" with "to" in page text
	# "from" may be regex
		self.text = self.text.send( (once ? 'sub' : 'gsub'), from, to )
	end
	def gsub from, to
		self.replace from, to
	end
	def sub from, to
		self.replace from, to, true
	end
	
	def append txt, newlines=2
	# appends newlines and text
	# by default - 2 newlines
		self.text = self.text.rstrip + ("\n"*newlines) + txt
	end
	
	def prepend txt, newlines=2
	# prepends text and newlines
	# by default - 2 newlines
		self.text = txt + ("\n"*newlines) + self.text.lstrip
	end
	
	def code_cleanup
	# simple, safe code cleanup
	# use Sunflower.always_do_code_cleanup=true to do it automatically just before saving page
	# based on Nux's cleaner: http://pl.wikipedia.org/wiki/Wikipedysta:Nux/wp_sk.js
		str=self.text.gsub(/\r\n/,"\n")
		
		str.gsub!(/\{\{\s*([^|{}]+ |uni|)stub2?(\|[^{}]+)?\}\}/i){
			if $1=='sekcja '
				'{{sekcja stub}}'
			else
				'{{stub}}'
			end
		}
		str.gsub!(/\{\{\{(?:poprzednik|następca|pop|nast|lata|info|lang)\|(.+?)\}\}\}/i,'\1')
		str.gsub!(/(={1,5})\s*Przypisy\s*\1\s*<references\s?\/>/i){
			if $1=='=' || $1=='=='
				'{{Przypisy}}'
			else
				'{{Przypisy|stopień= '+$1+'}}'
			end
		}
		
		str.gsub!(/\[\[([^\|#\]]*)([^\|\]]*)(\||\]\])/){
			name, anchor, _end = $1, $2, $3
			
			begin
				name = name.gsub(/((?:%[0-9a-fA-F]{2})+)/){ [$1.delete('%')].pack('H*') }
				anchor = (anchor||'').gsub(/\.([0-9A-F]{2})/, '%\1').gsub(/((?:%[0-9a-fA-F]{2})+)/){ [$1.delete('%')].pack('H*') }
				a='[['+name+anchor+(_end||'')
				a=a.gsub '_', ' '
			rescue
				a=('[['+name+(anchor||'')+(_end||'')).gsub '_', ' '
			end
			
			a
		}
		
		# sklejanie skrótów linkowych
		str.gsub!(/m\.? ?\[\[n\.? ?p\.? ?m\.?\]\]/, 'm [[n.p.m.]]');

		# korekty dat - niepotrzebny przecinek
		str.gsub!(/(\[\[[0-9]+ (stycznia|lutego|marca|kwietnia|maja|czerwca|lipca|sierpnia|września|października|listopada|grudnia)\]\]), (\[\[[0-9]{4}\]\])/i, '\1 \3');

		# linkowanie do wieków
		str.gsub!(/\[\[([XVI]{1,5}) [wW]\.?\]\]/, '[[\1 wiek|\1 w.]]');
		str.gsub!(/\[\[([XVI]{1,5}) [wW]\.?\|/, '[[\1 wiek|');
		str.gsub!(/\[\[(III|II|IV|VIII|VII|VI|IX|XIII|XII|XI|XIV|XV|XVIII|XVII|XVI|XIX|XXI|XX)\]\]/, '[[\1 wiek|\1]]');
		str.gsub!(/\[\[(III|II|IV|VIII|VII|VI|IX|XIII|XII|XI|XIV|XV|XVIII|XVII|XVI|XIX|XXI|XX)\|/, '[[\1 wiek|');

		# rozwijanie typowych linków
		str.gsub!(/\[\[ang\.\]\]/, '[[język angielski|ang.]]');
		str.gsub!(/\[\[cz\.\]\]/, '[[język czeski|cz.]]');
		str.gsub!(/\[\[fr\.\]\]/, '[[język francuski|fr.]]');
		str.gsub!(/\[\[łac\.\]\]/, '[[łacina|łac.]]');
		str.gsub!(/\[\[niem\.\]\]/, '[[język niemiecki|niem.]]');
		str.gsub!(/\[\[pol\.\]\]/, '[[język polski|pol.]]');
		str.gsub!(/\[\[pl\.\]\]/, '[[język polski|pol.]]');
		str.gsub!(/\[\[ros\.\]\]/, '[[język rosyjski|ros.]]');
		str.gsub!(/\[\[(((G|g)iga|(M|m)ega|(K|k)ilo)herc|[GMk]Hz)\|/, '[[herc|');

		# unifikacja nagłówkowa
		str.gsub!(/[ \n\t]*\n'''? *(Zobacz|Patrz) (też|także):* *'''?[ \n\t]*/i, "\n\n== Zobacz też ==\n");
		str.gsub!(/[ \n\t]*\n(=+) *(Zobacz|Patrz) (też|także):* *=+[ \n\t]*/i, "\n\n\\1 Zobacz też \\1\n");
		str.gsub!(/[ \n\t]*\n'''? *((Zewnętrzn[ey] )?(Linki?|Łącza|Stron[ay]|Zobacz w (internecie|sieci))( zewn[eę]trzn[aey])?):* *'''?[ \n\t]*/i, "\n\n== Linki zewnętrzne ==\n");
		str.gsub!(/[ \n\t]*\n(=+) *((Zewnętrzn[ey] )?(Linki?|Łącza|Stron[ay]|Zobacz w (internecie|sieci))( zewn[eę]trzn[aey])?):* *=+[ \n\t]*/i, "\n\n\\1 Linki zewnętrzne \\1\n");

		# nagłówki
		str.gsub!(/(^|\n)(=+) *([^=\n]*[^ :=\n])[ :]*=/, '\1\2 \3 ='); # =a= > = a =, =a:= > = a =
		str.gsub!(/(^|\n)(=+[^=\n]+=+)[\n]{2,}/, "\\1\\2\n");	# jeden \n

		# listy ze spacjami
		str.gsub!(/(\n[#*:;]+)([^ \t\n#*:;{])/, '\1 \2');
		
		# poprawa nazw przestrzeni i drobne okoliczne
		str.gsub!(/\[\[(:?) *(image|grafika|file|plik) *: *([^ ])/i){'[['+$1+'Plik:'+$3.upcase}
		str.gsub!(/\[\[(:?) *(category|kategoria) *: *([^ ])/i){'[['+$1+'Kategoria:'+$3.upcase}
		str.gsub!(/\[\[ *(:?) *(template|szablon) *: *([^ ])/i){'[['+'Szablon:'+$3.upcase}
		str.gsub!(/\[\[ *(:?) *(special|specjalna) *: *([^ ])/i){'[['+'Specjalna:'+$3.upcase}
		
		3.times { str.gsub!('{{stub}}{{stub}}', '{{stub}}') }
		
		self.text = str
	end
	
	def friendly_infobox
	# cleans up infoboxes
	# might make mistakes! use at your own risk!
		def makeFriendly(nazwa,zaw)
			zaw.gsub!(/<!--.+?-->/,'')
			nazwa=nazwa.gsub('_',' ').strip
			
			#escapowanie parametrów
			zaw.gsub!(/<<<(#+)>>>/,"<<<#\\1>>>")
			#wewnętrzne szablony
			while zaw=~/\{\{[^}]+\|[^}]+\}\}/
				zaw.gsub!($&,$&.gsub(/\|/,'<<<#>>>'))
			end
			#wewnętrzne linki
			while zaw=~/\[\[[^\]]+\|[^\]]+\]\]/
				zaw.gsub!($&,$&.gsub(/\|/,'<<<#>>>'))
			end
			
			zaw.sub!(/\A\s*\|\s*/,'') #usunięcie pierwszego pipe'a
			lines=zaw.split('|')
			
			# te tablice przechowują odpowiednio nazwy i wartości kolejnych parametrów
			names=[]
			values=[]
				
			for line in lines
				line.gsub!(/<<<#>>>/,'|')
				line.gsub!(/<<<#(#+)>>>/,"<<<\\1>>>") #odescapowanie
				
				line=~/\A\s*(.+?)\s*=\s*([\s\S]*?)\s*\Z/
				if $&==nil
					next
				end
				name=$1.strip
				value=$2.strip
				
				names<<name
				values<<value
			end
			
			zaw=''
			names.each_index{|i|
				zaw+=' | '+names[i]+' = '+values[i]+"\n"
			}
			
			# grupowane koordynaty
			zaw.gsub!(/\s*\| minut/, ' | minut')
			zaw.gsub!(/\s*\| sekund/, ' | sekund')
			
			return '{{'+nazwa[0,1].upcase+nazwa[1,999]+"\n"+zaw+'}}'+"\n"
		end

		nstr=''
		while str!=''
			str=~/(\s*)\{\{([^|}]+[ _]infobo[^|}]+|[wW]ładca)((?:[^{}]|[^{}][{}][^{}]|\{\{(?:[^{}]|[^{}][{}][^{}]|\{\{[^{}]+\}\})+\}\})+)\}\}(?:\s*)/
			
			spaces=($1!='' ? "\n" : '')
			before=($`==nil ? '' : $`)
			name=$2
			inner=$3
			match=$&
			if match!=nil
				result=makeFriendly(name,inner)
				nstr+=before+spaces+result
			else
				nstr+=str
				break
			end
			
			str=str.sub(before+match,'')
		end
	
		self.text = nstr
	end
	
	def change_category from, to
		from=from.sub(/\A\s*([cC]ategory|[kK]ategoria):/, '').strip
		to=to.sub(/\A\s*([cC]ategory|[kK]ategoria):/, '').strip
		self.text = self.text.gsub(/\[\[ *(?:[cC]ategory|[kK]ategoria) *: *#{Regexp.escape from} *(\|[^\]]*|)\]\]/){'[[Kategoria:'+to+($1=='| ' ? $1 : $1.rstrip)+']]'}
	end
end