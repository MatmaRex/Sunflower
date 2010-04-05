require 'sunflower-commontasks.rb'

# EDIT WIKI URL BELOW
s=Sunflower.new('en.wikipedia.org')

print "Logging in to #{s.wikiURL}... "
# EDIT USERNAME AND PASSWORD BELOW
s.login('Username','password')
print "done!\n"

print "Reading articles list... "
# EDIT FILENAME BELOW
f=File.open('filename.txt')
list=f.read.sub(/\357\273\277/,'').strip.split(/\r?\n/)
print "done!\n\n"

# EDIT SUMMARY BELOW
$summary='Sunflower: test'

list.each do |title|
	print "Reading page #{title}... "
	page=Page.get(title)
	print "done.\n"
	print "Modifying... "

	page.execute([
	# commands to execute on each article
	# zostaną wykonane w takiej kolejności, jak podane; wywal albo zakomentuj i wstaw własne
	# EDIT BELOW
		[:replace, 'test1', 'test2', true], #zamieni pierwsze wystąpienie test1 na test2 w artykule
		[:replace, 'asd', 'fgh'], #jw., ale zamieni każde wystąpienie
		[:replace, /(\d+).(\d+)/, '\1,\2'], #jw., ale używając regeksów; należy używać \1, nie $1
		[:prepend, 'Some text.'], #doda na początku artykułu dwa entery i tekst
		[:append, 'Some more text.', 4], #jw., ale na końcu i 4 entery; można podać dowolną liczbę
		[:code_cleanup], #część WP:SK, zamierzam uzupełnić
		[:friendly_infobox], #oczyszczony sprzątacz infoboksów
		
		#a teraz przykłady flag; też je wywal/zakomentuj
		#każda flaga ma skróty; required=r, summary=s - można używać zamiennie
		[[:replace, 'required'], 'qwe', 'rty'] #zamieni każde qwe na rty; jeśli nie uda mu się wykonać żadnych zmian, anuluje wszystko, co zrobiły inne polecenia oraz nie będzie zapisywał artykułu
		[:replace, 'r', 'summary:testowy opis'], 'qwe', 'rty'] #jw., ale w razie sukcesu doda tekst (wraz z przecinkiem) do opisu zmian; można używać dowolnej liczby flag dla jednego polecenia, w dowolnej kolejności
		
		#Teoretycznie możliwe jest też użycie flag only-if oraz only-if-not (skróty: oi, !oi; po dwukropku trzeba podać nazwę modułu (np. replace), który musi/nie może zostać uruchomiony i wykonać zmian, aby uruchomił się moduł oznaczony flagą. Ale to trochę bez sensu, bo w gruncie rzeczy nie wiadomo, co taki replace zrobił, a na razie wszystkie pozostałe zawsze coś zmienią. Kiedyś jednak może się przydać).
	# EDIT ABOVE
	])
	
	print "done.\n"
	print "Saving... "
	page.save
	print "done!\n\n"
end

print 'Finished! Press any key to close.'
gets