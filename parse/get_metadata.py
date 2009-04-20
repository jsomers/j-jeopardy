import os, re, urllib2

metadata = open('./metadata.txt', 'w')
for season in range(1, 26):
	print season
	url = 'http://www.j-archive.com/showseason.php?season=' + str(season)
	header = {'User-Agent':'JJ Bot'}
	response = urllib2.urlopen(urllib2.Request(url,[],header))
	raw = [a.strip() for a in response.readlines()]
	
	game_ids = []
	raw = ' '.join(raw)
	re_game = re.compile('<tr>(.*?)</tr>')
	re_game_id = re.compile('game_id=([0-9]+)')
	re_metadata = re.compile('<td valign="top" class="left_padded">(.*?)</td>')
	for game in re_game.findall(raw):
		game_id = re_game_id.findall(game)[0]
		meta = re_metadata.findall(game)[0].strip()
		if meta:
			metadata.write(game_id + ' ' + meta + '\n')