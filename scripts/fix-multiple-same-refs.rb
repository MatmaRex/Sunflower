require 'sunflower-commontasks.rb'
require 'sunflower-listmaker.rb'

# EDIT WIKI URL BELOW
s=Sunflower.new

print "Logging in to #{s.wikiURL}... "
# EDIT USERNAME AND PASSWORD BELOW
s.login
print "done!\n"

print "Reading articles list... "
# EDIT FILENAME BELOW
list=s.make_list('file', 'multirefs.txt')
print "done!\n\n"

# EDIT SUMMARY BELOW
$summary='poprawa powtarzających się przypisów, [[WP:SK]]'

list.each do |title|
	$refcount=0
	
	print "Reading page #{title}... "
	#page=Page.get(title)
	page=Page.new
	page.text=<<EOF
'''Abraham von Dohna''' (ur. [[11 grudnia]] [[1561]]r., zm. [[1 maja]] [[1613]] r. we [[Wrocław]]iu) – władca [[Syców|sycowskiego]] [[wolne państwo stanowe|wolnego państwa stanowego]] od [[1592]]<ref>A. i A. Galasowie, ''Dzieje Śląska w datach'', wyd. Rzeka, Wrocław 2001, s. 353.</ref>

==Rodzina i pochodzenie==
Pochodził z [[Prusy|pruskiego]] [[Ród Dohnów|rodu von Dohna]], osiadłego na [[Śląsk]]u w [[XIII]] w. Był synem Abrahama von Dohna seniora, który był [[starosta|starostą]] [[Księstwo głogowskie|głogowskim]]. W [[1587]] r. poślubił Eleonorę von Saurma-Jeltsch.<ref>T. Kulak, W. Mrozowicz, ''Syców i okolice od czasów najdawniejszych po współczesność'', s. 47.</ref> 

==Kariera polityczna==
Był aktywny politycznie. Wcześnie rozpoczął karierę na [[dwór|dworze cesarskim]] uczestnicząc w licznych misjach dyplomatycznych na terenie [[Polska|Polski]] i [[Rosja|Rosji]], gdzie zabiegał o pogodzenie obu zwaśnionych państw w obliczu zagrożenia ze strony [[Imperium Osmańskie]]go oraz do [[Hiszpania|Hiszpanii]]. W [[1596]] r. został mianowany [[wójt|wójtem krajowym]] [[Łużyce|Łużyc Górnych]].<ref>''Ibidem'', s. 47.</ref> 

==Wolny pan stanowy Sycowa==
Ożenek z bogatą Eleonorą von Saurma-Jeltsch zapewnił mu znaczne fundusze na zakup sycowskiego wolnego państwa stanowego od zadłużonego [[Georg Wilhelm von Braun|Jerzego Wilhelma von Braun]] w [[1592]] r.<ref>''Ibidem'', s. 47.</ref>  

Udało mu się zakończyć wieloletni spór o [[Międzybórz]] i okolice, który zakończył się jego utrata na rzecz [[Księstwo oleśnickie|księstwa oleśnickiego]]. W latach [[1604]]-[[1605|05]] za kwotę 50 tys. talarów nabył majątek [[Goszcz]]. Uregulował kwestie następstwa tronu w sycowskim wolnym państwie stanowym po swojej śmierci poprzez ustanowienie zasady [[primogenitura|primogenitury]], która została zatwierdzona przez [[cesarz]]a [[Rudolf II Habsburg|Rudolfa II]] w [[1600]] r.<ref>''Ibidem'', s. 48.</ref>  

W [[1594]] r. rozpoczął budowę nowego [[Zamek w Sycowie|zamku]] w [[Syców|Sycowie]] razem z parkiem, która zastąpiła dotychczasowy zamek, który częściowo znajdował się w ruinie po oblężeniu za panowania [[Joachim I von Maltzan|Joachima von Maltzana]]. Ukończoną ją w [[1608]] r. 

===Sprawy religijne===
W [[1592]] r. wydał przywilej gwarantujący na terenie swojego państwa wolność religijna i uprawnienie dla [[Protestantyzm|protestantów]]. Chociaż  wychował się w duchu protestantyzmu wyraźnie sprzyjał [[Katolicyzm|katolikom]], odbierając w [[1601]] r. sycowskim protestantom [[Kościół św. Piotra i Pawła w Sycowie|kościół św. Piotra i Pawła]], pozostawiając w ich rękach mniejszy kościół p.w. św. Michała.<ref>''Ibidem'', s. 47.</ref>   

===Sprawy gospodarcze i poszerzenie granic władztwa===
Podczas swoich rządów wykazał się dużą dbałością o zarządzanie swoimi dobrami. W [[1592]] r. dokupił [[Dziadowa Kłoda|Dziadową Kłodę]], a cztery lata później przyłączył dwie części [[Trębaczów|Trębaczowa]], sprzedając przy okazji [[Komorów]].<ref>''Ibidem'', s. 47.</ref> Od miasta [[Syców|Sycowa]] odkupił prawo wyszynku piwa i wina oraz kilka stawów rybnych. Na terenie swoich włości zakładał nowe [[folwark]]i oraz bażanciarnię. Zaradził uprawę [[winorośl]]i, [[chmiel]]u, owoców i warzyw. Rozwijała się gospodarka leśna i rybno-stawowa.<ref>''Ibidem'', s. 48.</ref>

==Ostatnie lata życia i śmierć==
Pod koniec życia z powodu rozwijającego się [[artretyzm]]u zrezygnował z urzędu wójta Górnych Łużyc ([[1612]] r.) Niedługo potem,[[1 maja]] [[1613]] r. zmarł we [[Wrocław]]iu, zaś jego ciało zostało przewiezione do Sycowa, gdzie został pochowany [[28 czerwca]] w zbudowanej na jego prośbę nowej krypcie rodzinnej, która stanęła pod północna kaplicą boczną kościoła parafialnego św. Piotra i  św. Pawła.<ref>''Ibidem'', s. 48.</ref> 

== Bibliografia ==
* [[Teresa Kulak|T. Kulak]], [[Wojciech Mrozowicz|W. Mrozowicz]], ''Syców i okolice od czasów najdawniejszych po współczesność'', wyd. Oficyna wydawnicza ''Atut'', Wrocław-Syców 2000.
* J. Franzkowski, ''Geschichte der freien Standesherrschaft, der Stadt und des landrätlichen Kreises Gross Wartenberg'', Gross Wartenberg 1912.

== Przypisy==
<references/>

{{Poprzednik Następca|urząd=[[Plik:POL Syców COA.svg|40px]]   [[Syców|Wolny pan stanowy Sycowa]]     [[Plik:POL Syców COA.svg|40px]]|lata=[[1592]]- [[1613]]|pop=[[Georg Wilhelm von Braun]]|nast=[[Karl Hannibal von Dohna]]}}


[[Kategoria:Urodzeni w 1561]]
[[Kategoria:Zmarli w 1613]]

[[de:Abraham von Dohna]]
EOF
	print "done.\n"
	print "Modifying... "

	page.replace("\r\n", "\n")
	
	30.times do
		page.text=page.text.sub( # that's ugly, but simpliest
			/<ref(?: name="([^"]+|)"|)>(.+?)<\/ref>([\s\S]+?)<ref(?: name="[^"]+"|)>\2<\/ref>(?:([\s\S]+?)<ref(?: name="[^"]+"|)>\2<\/ref>)?(?:([\s\S]+?)<ref(?: name="[^"]+"|)>\2<\/ref>)?(?:([\s\S]+?)<ref(?: name="[^"]+"|)>\2<\/ref>)?(?:([\s\S]+?)<ref(?: name="[^"]+"|)>\2<\/ref>)?(?:([\s\S]+?)<ref(?: name="[^"]+"|)>\2<\/ref>)?(?:([\s\S]+?)<ref(?: name="[^"]+"|)>\2<\/ref>)?(?:([\s\S]+?)<ref(?: name="[^"]+"|)>\2<\/ref>)?(?:([\s\S]+?)<ref(?: name="[^"]+"|)>\2<\/ref>)?/
		) do
			# $1 = name pierwszego refa; $2 = tekst refów; $3..n = teksty między refami
			name=($1.to_s!='' ? $1.to_s : 'auto-'+($refcount=$refcount+1).to_s)
			res='<ref name="'+name+'">'+$2+'</ref>'+$3+'<ref name="'+name+'" />'
			
			i=4
			while(! eval("$#{i}").nil?)
				res+=eval("$#{i}")+'<ref name="'+name+'" />'
				i=i+1
			end
			
			res
		end
	end
	
	page.codeCleanup
	
	
	
	print "done.\n"
	print "Saving... "
	#page.save
	page.dumpto 'reftest.txt'
	gets
	print "done!\n\n"
end

print 'Finished! Press any key to close.'
gets