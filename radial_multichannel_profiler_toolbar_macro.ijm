    macro "Radial average profiler Action Tool - Cf0fO22ccL2255LbbeeLb5e2L2e5bL8084L8b8fLb8f8L0848" {

setBatchMode(true);
stackid = getImageID();

//these are neccesary for the getdimensions, getposition calls
var stackwidth = 1;
var stackheight = 1;
var stackchannels = 1;
var stackslices = 1;
var stackframes = 1;

var currentchannel = 1;
var currentslice = 1;
var currentframe = 1;


var currentactivechannels = "hello space-man"
var currentmode = "nice try zarflax";

Stack.getPosition(currentchannel, currentslice, currentframe);
Stack.getDimensions(stackwidth, stackheight, stackchannels, stackslices, stackframes);

if  (Stack.isHyperstack | is("composite")) {
	Stack.getActiveChannels(currentactivechannels);
	Stack.getDisplayMode(currentmode);
	//switch to color so the profile ends up in 32-bit mode not RGB
	Stack.setDisplayMode("color");
	Stack.setChannel(1);
}

//get the pixel coordinates of the selection "center" - this will uniquely identify the selection

var selx = 1;
var sely = 1;
var selwidth = 1;
var selheight = 1;


getSelectionBounds(selx, sely, selwidth, selheight);
selxc = (selx + selx + selwidth)/2;
selyc = (sely + sely + selheight)/2;




//set up the column headers
var columntitles = "\\Headings:id\tx\t\y\t\z\tf\tc\tradialCoord\tpixelValue";


if (! isOpen("Scores")) {	
	var id = 1;
	
	//if no results window then we need to ask for length
	Dialog.create("Measure radial profile...");
	Dialog.addNumber("Profile width (pixels):", 10);
	Dialog.show();
	var pLength = Dialog.getNumber();
	
} else {
	//reuse length, increment id
	selectWindow("Scores");
	lines = split(getInfo(), "\n");
	if (lines.length==1) 
		{ var id=1; 
		//length is one if the table's been cleared, ask user to close empty table
		exit("Please close the empty results table...");
		} 
	else {
		headings = split(lines[lines.length-1], "\t");
		values = split(lines[lines.length-1], "\t");
		var id = parseInt(values[0]) + 1; 
	}
	var pLength = parseInt(values[6]);
}

run("Overlay Options...", "stroke=magenta width=" + pLength + " fill=none");
run("Add Selection...");
setColor(255, 0, 255);
Overlay.drawString('To hide measured regions: Image->Overlay->Remove Overlay', 20, 20);

//QUIT ROI MANAGER TO START
if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
	run("Close");
}
roiManager("Add");
//run("Add to Manager");
roiManager("Select", 0);
roiManager("Remove Slice Info");

var datastringheader = "" + id + "\t" + selxc + "\t" + selyc + "\t" + currentslice + "\t" + currentframe + "\t";


if (! isOpen("Scores")) {	
	run("New... ", "name=Scores type=Table");
	print("[Scores]", columntitles);
}

//there seems to be a race condition with opening up batch mode, so we'll wait until the 
//Scores window is actually visible before continuing
//while(! isOpen("Scores")) {
//	log("waiting...");
//}

//iterate through channels
for (i=1;i<=stackchannels;i++)	{
	
	selectImage(stackid);
	if  (Stack.isHyperstack | is("composite")) {
		Stack.setChannel(i);
	}
	roiManager("Select", 0);
	run("Area to Line");
	run("Straighten...", "line=" + pLength);
	run("Select All");
	run("Rotate 90 Degrees Left");
	run("Select All");
	channelprofile=getProfile();
	//print(getInfo("window.title"));
	close();
	//run("Close");
	
	if (! isOpen("Scores")) {	
		run("New... ", "name=Scores type=Table");
		print("[Scores]", columntitles);
	}
	for (j=0;j<pLength;j++) {
		datastring = datastringheader + i + "\t" + (j+1) + "\t" + channelprofile[j];
		print("[Scores]", datastring);
	}
}

roiManager("Select", 0);
roiManager("reset");
if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
	run("Close");
}

if  (Stack.isHyperstack | is("composite")) {
	Stack.setChannel(currentchannel);
	Stack.setDisplayMode(currentmode);
	Stack.setActiveChannels(currentactivechannels);
}
setBatchMode(false);
    }
