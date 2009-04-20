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
			game_id = game_id[0]
			game_ids.append(game_id)

	# Get games
	for game_id in game_ids:
		f = open('season ' + str(season) + '/' + game_id + '.txt', 'w')
		url = 'http://www.j-archive.com/showgame.php?game_id=' + game_id
		header = {'User-Agent':'JJ Bot'}
		response = urllib2.urlopen(urllib2.Request(url,[],header))
		raw = [a.strip() for a in response.readlines()]
	
		category_names = []
		for line in raw:
			re_category_name = re.compile('<td class="category_name">(.*?)</td>')
			category_name = re_category_name.findall(line)
			if category_name:
				category_name = category_name[0]
				category_names.append(category_name)
	
			if line.count('<title>'):
				show_name = line.replace('<title>', '').replace('</title>', '').replace('J! Archive -', '')
		f.write(show_name.strip() + '\n\n')
		for category in category_names:
			f.write(category.strip() + '\n')
		f.write('\n')
	
		starts = []
		ends = []
		for i, line in enumerate(raw):
			if line.count('<td class="clue">'):
				starts.append(i)
				ends.append(i + 17)
		clue_indexes = zip(starts, ends)
	
		for index in clue_indexes[:-1]:
			clue = ' '.join(raw[index[0]:index[1]])
			re_clue_value = re.compile('<td class="clue_value">\$([0-9]+)</td>')
			clue_value = re_clue_value.findall(clue)
			if clue_value:
				clue_value = clue_value[0]
			if clue.count('<td class="clue_value_daily_double"'):
				clue_value = 'DD'
		
			re_question = re.compile('class="clue_text">(.*?)</td>')
			question = re_question.findall(clue)
			if question:
				question = question[0]
		
			re_answer = re.compile('correct_response(.*?)br \/')
			answer = re_answer.findall(clue)
			if answer:
				answer = answer[0]
		
			re_clue_coordinates = re.compile('td id="clue_D?J_[0-9]_[0-9]"')
			clue_coordinates = re_clue_coordinates.findall(clue)
			if clue_coordinates:
				clue_coordinate = clue_coordinates[0].replace('td id="', '').replace('"', '').replace('clue_', '').replace('_', ',')
		
			try:
				f.write(clue_coordinate + '\n')
				f.write(clue_value + '\n')
				f.write(question + '\n')
				f.write(answer + '\n')
				f.write('\n')
			except:
				f.write('ERROR')
			
		f.close()