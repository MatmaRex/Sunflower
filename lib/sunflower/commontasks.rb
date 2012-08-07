# coding: utf-8

class Sunflower::Page
	# replaces "from" with "to" in page text
	# "from" may be regex
	def replace from, to, once=false
		self.text = self.text.send( (once ? 'sub' : 'gsub'), from, to )
	end
	def gsub from, to
		self.replace from, to
	end
	def sub from, to
		self.replace from, to, true
	end
	
	# appends newlines and text
	# by default - 2 newlines
	def append txt, newlines=2
		self.text = self.text.rstrip + ("\n"*newlines) + txt
	end
	
	# prepends text and newlines
	# by default - 2 newlines
	def prepend txt, newlines=2
		self.text = txt + ("\n"*newlines) + self.text.lstrip
	end
	
	# plwiki-specific cleanup routines.
	# based on Nux's cleaner: http://pl.wikipedia.org/wiki/Wikipedysta:Nux/wp_sk.js
	def code_cleanup_plwiki str
		str = str.dup
		
		str.gsub!(/\{\{\{(?:poprzednik|następca|pop|nast|lata|info|lang)\|(.+?)\}\}\}/i,'\1')
		str.gsub!(/(={1,5})\s*Przypisy\s*\1\s*<references\s?\/>/i){
			if $1=='=' || $1=='=='
				'{{Przypisy}}'
			else
				'{{Przypisy|stopień= '+$1+'}}'
			end
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

		return str
	end
	
	# simple, safe code cleanup
	# use Sunflower.always_do_code_cleanup=true to do it automatically just before saving page
	def code_cleanup
		str = self.text.gsub /\r\n/, "\n"
		
		str.gsub!(/\[\[([^\|\]]+)(\||\]\])/){
			name, rest = $1, $2
			"[[#{self.sunflower.cleanup_title name, false}#{rest}"
		}
		
		# headings
		str.gsub!(/(^|\n)(=+) *([^=\n]*[^ :=\n])[ :]*=/, '\1\2 \3 ='); # =a= > = a =, =a:= > = a =
		str.gsub!(/(^|\n)(=+[^=\n]+=+)[\n]{2,}/, "\\1\\2\n"); # one newline

		# spaced lists
		str.gsub!(/(\n[#*:;]+)([^ \t\n#*:;{])/, '\1 \2');
		
		if wikiid = self.sunflower.siteinfo['general']['wikiid']
			if self.respond_to? :"code_cleanup_#{wikiid}"
				str = self.send :"code_cleanup_#{wikiid}", str
			end
		end
		
		self.text = str
	end

	# Replace the category from with category to in page wikitext.
	# 
	# Inputs can be either with the Category: prefix (or localised version) or without.
	def change_category from, to
		cat_regex = self.sunflower.ns_regex_for 'Category'
		from = self.sunflower.cleanup_title(from).sub(/^#{cat_regex}:/, '')
		to   = self.sunflower.cleanup_title(to  ).sub(/^#{cat_regex}:/, '')
		
		self.text.gsub!(/\[\[ *#{cat_regex} *: *#{Regexp.escape from} *(\||\]\])/){
			rest = $1
			"[[#{self.sunflower.ns_local_for 'Category'}:#{to}#{rest}"
		}
	end
end
