nope1 = false;
nope2 = false;
nope3 = false;
function playMusic(nm) {
	obj = document.embeds[nm];
	if(obj.Play) obj.Play();
	return true;
}
var ct = 0;

function getArrows(ev, p1, p2, p3) {
    arrows = ((ev.which) || (ev.keyCode));
    
    //ev = false;
    if (ct > 0 || seconds > 5.0) {
		switch(arrows) {
			case 65:
				nope1 = true;
				break;
			case 66:
				nope2 = true;
				break;
			case 80:
				nope3 = true;
				break;
		}
        return '0'
    } else {
        //ev = false;
        switch(arrows) {
            case 65:
				if (nope1 && seconds > 4.0) {
					return '0'
				} else {
                $('ffinger').value = p1 + ':';
                $('player').value = '1';
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
            case 66:
				if (nope2 && seconds > 4.0) {
					return '0'
				} else {
                $('ffinger').value = p2 + ':';
                $('player').value = '2';
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
            case 80:
				if (nope3 && seconds > 4.0) {
					return '0'
				} else {
                $('ffinger').value = p3 + ':';
                $('player').value = '3';
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