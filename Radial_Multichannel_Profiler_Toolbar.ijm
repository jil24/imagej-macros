macro "Radial Average Profiler Action Tool - Cf0fO22ccL2255LbbeeLb5e2L2e5bL8084L8b8fLb8f8L0848" {

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


var currentactivechannels = ""
var currentmode = "";

Stack.getPosition(currentchannel, currentslice, currentframe);
Stack.getDimensions(stackwidth, stackheight, stackchannels, stackslices, stackframes);

if  (Stack.isHyperstack || is("composite")) {
	Stack.getActiveChannels(currentactivechannels);
	Stack.getDisplayMode(currentmode);
}

//get the pixel coordinates of the selection "center" - this will uniquely identify the selection

var selx = 1;
var sely = 1;
var selwidth = 1;
var selheight = 1;


getSelectionBounds(selx, sely, selwidth, selheight);
selxc = (selx + selx + selwidth)/2;
selyc = (sely + sely + selheight)/2;

//determine whether the selection is going clockwise (positive) or counterclockwise (negative)
//0 = rect - always cw
//1 = oval - always cw
//2 = polygon - cw or ccw depending on point selection order
//3 = freehand - cw or ccw depending on draw direction

getSelectionCoordinates(xs, ys);

seltype =  selectionType();
if (seltype<3) { //if oval, rect, or polgon, convert to raster
	run("Interpolate", "interval=2"); //use 2 to prevent overly rough looking outline
	getSelectionCoordinates(xs, ys);
}

npoints=lengthOf(xs);

direction = 0;
for (i=0;i<npoints;i++) {
	direction = direction + (xs[(i+1)%npoints]-xs[i])*(ys[(i+1)%npoints]+ys[i]);
}
direction = -1 * direction/abs(direction);


//set up the column headers
var columntitles = "\\Headings:id\tx\t\y\t\z\tf\tc\tradialCoord\tpixelValue";

if (isOpen("Scores")) {
	selectWindow("Scores");
	lines = split(getInfo(), "\n");
	if (lines.length==1) 
		{ 
		//length is one if the table's been cleared, start over 
		run("Close");
		} 
}

if (! isOpen("Scores")) {	
	var id = 1;
	
	//if no results window then we need to ask for length
	Dialog.create("Measure radial profile...");
	Dialog.addNumber("Profile width (pixels):", 10);
	Dialog.addChoice("Profile orientation:", newArray("outside to inside","inside to outside"));
	Dialog.show();
	var pLength = Dialog.getNumber();
	orientation = Dialog.getChoice();
	if (orientation == "outside to inside") {orientation = 1;} else {orientation = -1;}
	call("ij.Prefs.set", "radialchannelprofiler.orientation", orientation);
	
} else {
	//reuse length, increment id, orientation
	//pull the last-used orientation value from imageJ's preferences or use 0 as a default
	orientation = parseInt(call("ij.Prefs.get", "radialchannelprofiler.orientation", "1")); 
	
	selectWindow("Scores");
	lines = split(getInfo(), "\n");
	
	
	headings = split(lines[lines.length-1], "\t");
	values = split(lines[lines.length-1], "\t");
	var id = parseInt(values[0]) + 1; 
	
	var pLength = parseInt(values[6]);
}

//switch to color so the profile ends up in 32-bit mode not RGB
Stack.setDisplayMode("color");
//Stack.setChannel(1);
	
run("Overlay Options...", "stroke=magenta width=" + pLength + " fill=none");
run("Add Selection...");
setColor(255, 0, 255);
//Overlay.drawString('To hide measured regions: Image->Overlay->Remove Overlay', 20, 20);

//quit roi manager if open
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


//iterate through channels
for (i=1;i<=stackchannels;i++)	{
	
	selectImage(stackid);
	roiManager("Select", 0);
	if  (Stack.isHyperstack || is("composite")) {
		Stack.setChannel(i);
	}
	run("Area to Line");
	run("Straighten...", "line=" + pLength);
	//if (i == 2)	{setBatchMode("exit & display");exit;}
	run("Select All");
	run("Rotate 90 Degrees Left");
	
	run("Select All");
	channelprofile=getProfile();
	//reverse the profile if we're counterclockwise, so profile is always in same direction
	if ((direction * orientation) < 0) {
		channelprofile=Array.reverse(channelprofile);
	}
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

if  (Stack.isHyperstack || is("composite")) {
	Stack.setChannel(currentchannel);
	Stack.setDisplayMode(currentmode);
	Stack.setActiveChannels(currentactivechannels);
}
setBatchMode(false);
}

macro "Clear Outlines Action Tool - Cf0fO4477Cf00O00ffO11ddH1221edde" {
	 Overlay.remove();
}
