- multiplayer jeopardy blast
- jeopardy answer that would answer the most questions

- "make your own jeopardy game" could be a very important feature.

Ken Jennings games (against the world)

Special DD corrector using wager data?

How hard is Jeopardy? (% of questions correct)
How much harder is single than double Jeopardy?
How much harder is Tournament of Champions / regular than College / Teen? (Here we have players who are *not* geared to the game type.)

Fix images

API and widgets

game (aggregated)
	- mini board layout with pcts:
		* % not answered
		* % answered correctly
		* % answered incorrectly
	- for DDs, average wager
	- avg. scores for top, middle, and worst player
	- performance aggregated over the category (+/- in $s for the players; % correct)
	- click each question (chart or whatever) for individual analytics
	- final jeopardy percentages, wagers
	- percentile difficulty of all games

question
	- question text, answer (hidden)
	- guess list, collapsed (e.g., instead of "A, A, A, A, B, B, C, D", you'd have "A (50%), B (25%), C (12.5%), D (12.5%)")
	- # of times seen; # of correct answers; # of incorrect answers.
	- percentile difficulty overall (of all questions)

player
	- # of questions seen (rank)
	- # answered correctly (rank) / # incorrectly
	- # of games played (rank)
	- list of current episodes, with progress ("n of 61 questions") & current scores for each. Provides links to play. (Sets up session?)
	- list of finished episodes, links to episode analytics.
	- avg. score per game
	- win percentage
	- avg. wager in daily doubles
	- avg. wager in final jeopardy
	- "canonical" board:
		* performance strictly based on position
	- best categories

episode
	- normal board view, but with both rounds exposed and showing final jeopardy.
	- shows wager.

overall
	- # of episodes, accounting for completeness
	- # of players
	- # of questions answered; % correct, incorrect
	- superboard with pie charts based solely on position
