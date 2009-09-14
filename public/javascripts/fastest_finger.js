nope1 = false;

function playMusic(nm) {
	obj = document.embeds[nm];
	if(obj.Play) obj.Play();
	return true;
}
var ct = 0;

function getArrows(ev, p, place) {
	time_to_n = (seconds * 10) + milisec
    arrows = ((ev.which) || (ev.keyCode));
    
	if (arrows == 33) {
		window.location = home_url
	}
    //ev = false;
    if (ct > 0 || seconds > 5.0) {
		switch(arrows) {
			case p_key:
				nope1 = true;
				break;
		}
        return '0'
    } else {
        //ev = false;
        switch(arrows) {
            case p_key:
				if (nope1 && time_to_n > 55) {
					return '0'
				} else {
                $('ffinger').value = p + ':'; // Change these to the current player
                $('player').value = place;
                $('answer').style.display = '';
                $('guess').style.display = '';
                $('d2').style.color = '#211eab';
				$('out').style.width = '120px';
				$('out').style.borderColor = 'red';
				seconds = 3;
				milisec = 6;
				ct = ct + 1;
                break;
			}
        }
        //document.getElementById('answer').focus();
		//$('answer').value = '';
		ev.stop();
		$('answer').focus();
        //document.getElementById('answer').onkeypress = "return true;";
        
    }
}