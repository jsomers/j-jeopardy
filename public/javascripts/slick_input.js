var firstKeypress = true;

function keypress(tbox)
 {
    if (firstKeypress)
    {
        if (tbox.className == "inactive")
        tbox.value = "";

        tbox.className = "active";
        firstKeypress = false;
    }

    return true;
}

function enterTextbox(tbox)
 {

    if (tbox.className == "inactive")
    tbox.value = "";

    tbox.className = "active";
}

function leaveTextbox(tbox, label)
 {
    firstKeypress = false;
    if (tbox.value == "")
    {
        tbox.value = label;
        tbox.className = "inactive";
    }
}