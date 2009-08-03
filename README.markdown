## Getting started

To start a game, head to `/play/start` and enter your names. If you're only playing with two people, I'd use the first and third slots and leave the second one blank.

When you hit enter, that'll take you to `/play/choose_game`&mdash;where you can, obviously, choose a game. Pick one that sounds fun.

At the top of the board screen, one player's name (chosen randomly) should be underlined, which means it's their turn to select a category.

At this point you might want to go into "full-screen mode" on your browser. Close all tabs but the current one; hit the little button in the top-right corner of the window to get rid of the location bar; and go to **View -> Status Bar** to remove that. Minimize your Dock and drag the window as far as it can go.

## Fastest finger

The buzzers are: P1 = left, P2 = B, P3 = right. The reason they're wacky like that is because I've been playing with one person at the keyboard (B) and two guys using Wiimotes (in which case you don't want "typeable" letters, which is why you go with the arrows). These can be changed&mdash;reference this [Javascript keycodes page](http://www.cambiaresearch.com/c4/702b8cd1-e5b0-42e6-83ac-25f0306e3e25/Javascript-Char-Codes-Key-Codes.aspx) and change the corresponding values (everywhere you see `case 37`, `case 66`, and `case 39`) in the `fastest_finger.js` file in the `/public` folder.

When you choose a question, there will be a roughly four-second delay before an orange bar appears indicating that it's okay to buzz in. The idea is to give everyone time to read the question. (I may add a feature that varies this interval based on the length/difficulty of the question's text, but for now people seem to think the four seconds works nicely.)

If a player buzzes in early, they will be locked out for a quarter of a second. Jumping the gun multiple times will not add more lockout time (so if you know you're locked out, you might as well frantically jam the crap out of the buzzer).

Once someone buzzes in, a red bar will show up and start to shrink. Players must say their answer before the bar disappears, and if they don't, the person with the keyboard should just type gibberish into the box.

## Typing answers

The function for validating answers works by (1) assuming the guess is correct, (2) breaking the guess into words, and (3) checking to make sure each word of the guess is contained somewhere in the answer; if not, the player's wrong. Case doesn't matter.

One helpful rule of thumb is: if the spelling of something is ambiguous, leave it out. If you're not sure whether it's "Bonnie and Clyde" or "Bonnie & Clyde", just type "bonnie clyde". If you think it's "Bonny and Clide", try "bon cli". Go with enough to unambiguously pin down an answer, and no more.

If the validator calls a guess incorrect when everyone actually thinks it's right, and the reason is spelling or punctuation or whatever, just submit a blank guess enough times to get the score to where it should be (because a blank guess is assumed to be correct). If you're not sure, play as though the validator is correct and if you need to, use the little "correctors" after you get back to the main game board. That way you don't risk seeing a correct answer before everyone has taken an honest crack at it.

## Correctors

Those cute little check marks and red X's and white dots are actually clickable, and they'll change a player's score appropriately. They can also be used to switch the player in control&mdash;just cycle through any one of that player's correctors and you'll see the underline move to their name.

## Daily doubles

These are hidden in the board, and they should work as expected. They make that familiar sound when you click them so be sure to have your speakers on.

First, make a wager (must be at least $5), submit it, and answer the question. Players are given 15 seconds, which again gives them time to read and think a bit. Don't feel pressed to type the answer before the 15 seconds is up&mdash;you just have to say it before then. All that happens when the time runs out is that you're prompted to type in a guess.

If there's a dispute here, fix it by playing with the text box (either by just hitting "enter" or by typing gibberish); there aren't correctors yet for daily doubles.

## Final jeopardy

When the game is nearly done, there should be a link to final jeopardy. The first thing you'll see is a wagering screen: three text boxes with "Lock" links beneath them. Hitting the "Lock" link will just password-ize and hide the text in the box above it; the idea is to allow people to see their wager as they type (so as not to make mistakes), but hide it from everyone else once they're done. Alternatively, you can hit lock before you type, if you're using a wireless keyboard and everyone's playing on a big TV.

Once all the wagers are in, hit Submit and head to the question page. The "think" music will play, and you must settle on an answer in your mind by the time the music's finished; if you can't think of anything by then, type gibberish into the box. (Honor system!)

Make sure everyone knows to be careful typing their answers here; have them type as little as possible while still pinning down an unambiguous guess. Have them avoid conjunctions, punctuation (if it's "jacob's ladder", type "jacob ladder"), etc. If you're not sure whether something is one compound word or two words broken by a space or hyphen, type two words broken by a space (type "post man", not "postman").

On the game over screen, if you're connected to the internet you should see a "Game progress" graph (built using google charts) in addition to the overall outcome of the game, as well as the answer to the final jeopardy question.

## Wiimotes!

You'll need (a) a nice TV and hookup to your computer, (b) two or three wiimotes, (c) a sensor bar and Wii, and (d) a wireless (or long-wired) keyboard.

The first thing to do is set up the wiimotes. There's kind of a crazy procedure (takes two minutes but it's got to happen in a specific order), but it's totally worth it. First, [download Darwiin Remote here](http://sourceforge.net/projects/darwiin-remote/). Before you open the program, though, duplicate it however times you need (for however many wiimotes you need) and open up all the copies.

   1. Make sure your Wii is off to start.
   2. On one (and only one) of the control panels, select Mouse Mode On (IR) from the drop-down box. This'll be used by the main player in control (who types, too) to select questions from the board. It's not strictly necessary but it's kind of fun to point at the screen.
   3. One at a time, click "Find Wiimote" and hold 1 and 2 on the wiimote you're trying to associate with that control box. Test it by moving it around and clicking buttons. Make sure the wiimotes fire on different screens.
   4. The mouse won't work on the one that you indicated just yet. First, turn on your Wii&mdash;that'll activate the sensor bar. It's a bit overkill but works for the moment. Then, click the IR Sensor button the control panel for that wiimote. Then test it&mdash;it should work now.
   5. Head to Preferences and be sure to select the Wiimote tab; the program defaults to the Classic Controller tab and that's the wrong one.
   6. Change the B button (trigger) to "left click" and the A button (on the front; thumb button; this is the one you want to use for buzzer), on each wiimote, to the appropriate player's key. Left for P1, Right for P3, etc.
   7. Also, change the "home" button to Page Up.
   8. On the mouse-enabled wiimote's preferences pane, head to "Mouse" and decrease the IR sensitivity by two notches.
   9. Save&mdash;and ignore the "sensitivity too small" warning.

Now, hook the computer up to the TV. "Mirror" the displays, rather than arranging them side-by-side.

Everything should work as usual, just that the non-typing players should be able to buzz in by clicking their wiimotes. The typing / mouse-wiimote-wielding player should choose questions (like a Trebek would), buzz in like the other players, and type everyone's answers. Hit "page up" or the "home" button on the wiimote to head to the main board after a question's been completed (rather than clicking the "back to the board" links). Do click the "go back" links, though, if someone's tried and gotten it wrong, because the "page up" method won't reveal the correct answer.

It may be awkward at first if you're the player in control. The hardest things are clicking links with the Wiimote and switching to the keyboard. After about five questions, though, I got used to it and was moving around like a pro.

(One thing I might add is a way to choose questions using just the keyboard. So one player would just use a keyboard, no wiimote... might make things easier for them.)

## Hidden modes

   * Try going to `/play/search` to search clues.
   * At /play/blast there's a "one-player" game that will feed you questions. See line 7 of `/app/controllers/play_controller` to see how questions are being pulled in at the moment. I haven't added scoring to this yet or anything but it has potential I think. If you enter a blank answer it'll show you the correct response and move you to the next question.
   * If you go to `/edit/board/[id]`, you'll be able to edit that particular game. It's the beginning of a "custom game" feature and/or just to make corrections.

## That's it!

Let me know if you have other questions or ideas for improvement.