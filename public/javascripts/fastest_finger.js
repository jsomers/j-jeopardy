nope1 = false;
nope2 = false;
nope3 = false;

var startDictation = function() {
  if (window.hasOwnProperty('webkitSpeechRecognition')) {
    var recognition = new webkitSpeechRecognition();

    recognition.continuous = false;
    recognition.interimResults = false;

    recognition.lang = "en-US";
    recognition.start();
    
    document.getElementById('mic_icon').style.visibility = "visible";

    recognition.onresult = function(e) {
      document.getElementById('mic_icon').style.visibility = "hidden";
      recognition.stop();
      if (document.getElementById('answer').value.trim() === "") {
      	document.getElementById('answer').value = e.results[0][0].transcript;
      	document.getElementById('answer').focus();
      }
    };

    recognition.onerror = function(e) {
      document.getElementById('mic_icon').style.visibility = "hidden";
      recognition.stop();
    }
  }
}

function playMusic(nm) {
	obj = document.embeds[nm];
	if(obj.Play) obj.Play();
	return true;
}
var ct = 0;

function getArrows(ev, p1, p2, p3) {
  if (typeof(donezotronimo) !== 'undefined' && donezotronimo) return false;

	time_to_n = (seconds * 10) + milisec
    arrows = ((ev.which) || (ev.keyCode));
    
	if (arrows == 33) {
		window.location = home_url
	}
    //ev = false;
    if (ct > 0 || time_to_n > 50) {
		switch(arrows) {
			case p1_key:
				nope1 = true;
				break;
			case p2_key:
				nope2 = true;
				break;
			case p3_key:
				nope3 = true;
				break;
		}
        return '0'
    } else {
        //ev = false;
        switch(arrows) {
            case p1_key:
				if (nope1 && time_to_n > 55) {
					return '0'
				} else {
          startDictation();
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
            case p2_key:
				if (nope2 && time_to_n > 55) {
					return '0'
				} else {
          startDictation();
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
            case p3_key:
				if (nope3 && time_to_n > 55) {
					return '0'
				} else {
          startDictation();
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