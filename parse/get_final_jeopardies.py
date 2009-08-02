import os, re, urllib2

for season in range(25, 26):
	os.mkdir('season ' + str(season))
	# Get episode IDs
	url = 'http://www.j-archive.com/showseason.php?season=' + str(season)
	header = {'User-Agent':'JJ Bot'}
	response = urllib2.urlopen(urllib2.Request(url,[],header))
	raw = [a.strip() for a in response.readlines()]

	game_ids = []
	for line in raw:
		id_re = re.compile('http://www\.j\-archive\.com/showgame\.php\?game_id\=([0-9]+)')
		game_id = id_re.findall(line)
		if game_id:
			if int(game_id[0]) > 3028:
				game_id = game_id[0]
				game_ids.append(game_id)
			else:
				continue

	# Get games
	for game_id in game_ids:
		url = 'http://www.j-archive.com/showgame.php?game_id=' + game_id
		header = {'User-Agent':'JJ Bot'}
		response = urllib2.urlopen(urllib2.Request(url,[],header))
		raw = [a.strip() for a in response.readlines()]

		f = open('season ' + str(season) + '/' + game_id + '.txt', 'w')
		for line in raw:
			if line.count('clue_FJ'):
				re_fj_question = re.compile('clue_FJ" class="clue_text">(.*?)</td>')
				re_fj_answer = re.compile('correct_response\\\\&quot;&gt;(.*?)&lt;/em&gt;')
				fj_answer = re_fj_answer.findall(line)
				if fj_answer:
					fj_answer = fj_answer[0]
					f.write(fj_answer + '\n')
				fj_question = re_fj_question.findall(line)
				if fj_question:
					fj_question = fj_question[0]
					f.write(fj_question + '\n')