//Jonathan Lake 2013
//v1
//Public Domain

stackid = getImageID();
stackname=getTitle();

var stackwidth = 1;
var stackheight = 1;
var stackchannels = 1;
var stackslices = 1;
var stackframes = 1;
Stack.getDimensions(stackwidth, stackheight, stackchannels, stackslices, stackframes);

var thresholdsSet=false;
channelLowerThreshold = newArray(stackchannels);
channelUpperThreshold = newArray(stackchannels);
var cLT=0;
var cUT=0;

var currentchannel = 1;
var currentslice = 1;
var currentframe = 1;

var xCoordinates = 1;
var yCoordinates = 1;

Stack.getPosition(currentchannel, currentslice, currentframe);

//default values
var segmentchannel = currentchannel;
var minNucleusArea = 150;
var maxNucleusArea = "Infinity";
var diameter = 100;
var blur = false;
var review = true;
var reuseThresholds = false;
var whatToScore = "This frame only"
var segLT = 0;
var segUT = 0;

if (! isOpen("Segmentor Settings - close to reset")) {	
	var id = 1;
	
	//if no settings window then we need to ask for stuff
	Dialog.create("Circle-trimmed watershed-voronoi segmentor / scorer");
	Dialog.addMessage("Segmentation settings");
	Dialog.addNumber("Channel to segment (1-"+stackchannels+"):", segmentchannel);
	Dialog.addCheckbox("3px blur before segmentation?", blur);
	Dialog.addNumber("Minimum nucleus area:",minNucleusArea);
	Dialog.addNumber("Maximum nucleus area:",maxNucleusArea);
	Dialog.addNumber("Maximum scoring area diameter:",diameter);
	
	Dialog.addMessage("Scoring Settings:");
	Dialog.addCheckbox("Manually review segmentation?", review);
	Dialog.addCheckbox("Keep using the same thresholds?", reuseThresholds);
	
	//retreive values
	
	Dialog.show();
	segmentchannel = Dialog.getNumber();
	blur = Dialog.getCheckbox();
	minNucleusArea = Dialog.getNumber();
	maxNucleusArea = Dialog.getNumber();
	diameter = Dialog.getNumber();
	review = Dialog.getCheckbox();
	reuseThresholds = Dialog.getCheckbox();
		
	run("New... ", "name=[Segmentor Settings - close to reset] type=Table");
	print("[Segmentor Settings - close to reset]", segmentchannel);
	print("[Segmentor Settings - close to reset]", blur);
	print("[Segmentor Settings - close to reset]", minNucleusArea);
	print("[Segmentor Settings - close to reset]", maxNucleusArea);
	print("[Segmentor Settings - close to reset]", diameter);
	print("[Segmentor Settings - close to reset]", review);
	print("[Segmentor Settings - close to reset]", reuseThresholds);
	
} else {
	//load settings from window
	selectWindow("Segmentor Settings - close to reset");
	lines = split(getInfo(), "\n");
	if (lines.length==1) 
		{ var id=1; 
		//length is one if the table's been cleared, ask user to close empty table
		exit("Please close the empty settings window...");
		} 
	else {
		//headings = split(lines[lines.length-1], "\t");
		//values = split(lines[lines.length-1], "\t");
		//for(i=0;i<lines.length;i++){print(lines[i]);}

		if (lines.length>7) { thresholdsSet=true;}
		
		segmentchannel = parseInt(lines[0]);
		blur = parseInt(lines[1]);
		minNucleusArea = parseInt(lines[2]);
		maxNucleusArea = parseInt(lines[3]);
		diameter = parseInt(lines[4]);
		review = parseInt(lines[5]);
		reuseThresholds = parseInt(lines[6]);	
	}
}

var radius = diameter/2;

//ask for segmentation threshold on segmentation channel

if(thresholdsSet==true && reuseThresholds==true) {
		segthreshbreakpoints = split(lines[7], " ");
		segLT = parseInt(segthreshbreakpoints[0]);
		segUT = parseInt(segthreshbreakpoints[1]);
	
} else {
	run("Threshold...");
	Stack.setChannel(segmentchannel);
	setAutoThreshold("Default dark stack");
	waitForUser("Adjust Segmentation Threshold");
	getThreshold(cLT,cUT);
	segLT=cLT;
	segUT=cUT;
	if(reuseThresholds==true) {
		print("[Segmentor Settings - close to reset]", "" + cLT + " " + cUT);	
	}
	
	
}

//ask for channel scoring thresholds

if(thresholdsSet==true && reuseThresholds==true) {
	for(i=1;i<=stackchannels;i++){
		breakpoints = split(lines[i+7], " ");
		channelLowerThreshold[i-1] = parseInt(breakpoints[0]);
		channelUpperThreshold[i-1] = parseInt(breakpoints[1]);
	}
} else {
	run("Threshold...");
	for(i=1;i<=stackchannels;i++){
		Stack.setChannel(i);
		setAutoThreshold("Default dark stack");
		waitForUser("Adjust Threshold of Channel " + i);
		getThreshold(cLT,cUT);
		channelLowerThreshold[i-1]=cLT;
		channelUpperThreshold[i-1]=cUT;
		if(reuseThresholds==true) {
			print("[Segmentor Settings - close to reset]", "" + cLT + " " + cUT);	
		}
	}
	
}

Stack.setChannel(segmentchannel);
run("Duplicate...", "title=[for segmentation] duplicate channels=" + segmentchannel + " frames=" + currentframe);

if(blur == true) {
	run("Gaussian Blur...", "sigma=3");
}

forSegmentation=getImageID();

setThreshold(segLT,segUT);
setBatchMode(true);

run("Make Binary");
run("Fill Holes");
run("Analyze Particles...", "size="+ minNucleusArea +"-"+ maxNucleusArea +" circularity=0.00-1.00 show=Masks"); 
sizeFiltered=getImageID();
resetThreshold();
run("Watershed");
run("Duplicate...", "title=[voronoi cells]");
run("Voronoi");
setThreshold(1,255);
run("Make Binary", "thresholded remaining black");
voronoiCells=getImageID();
run("Invert");



selectImage(sizeFiltered);
run("Ultimate Points");
setThreshold(1,255);
run("Make Binary", "thresholded remaining black");
run("Points from Mask");
getSelectionCoordinates(xCoordinates, yCoordinates);
run("Close");


newImage("alpha", "8-bit black", stackwidth, stackheight, 1);
alpha = getImageID();
newImage("beta", "8-bit black", stackwidth, stackheight, 1);
beta = getImageID();
newImage("gamma", "8-bit black", stackwidth, stackheight, 1);
gamma = getImageID();


setColor(0);

for (i=0; i<xCoordinates.length; i++) {
	selectImage(voronoiCells);
	doWand(xCoordinates[i],yCoordinates[i]);
	run("Select None");
	selectImage(alpha);

	setColor(0);
	fillRect(0, 0, stackwidth, stackheight);
	setColor(255);
	
	run("Restore Selection");
	fill();
	
	selectImage(beta);
	setColor(0);
	fillRect(0, 0, stackwidth, stackheight);
	setColor(255);
	fillOval(xCoordinates[i]-radius,yCoordinates[i]-radius,diameter,diameter);
	
	imageCalculator("AND", "beta","alpha");
	imageCalculator("OR", "gamma","beta");
}
selectImage(gamma);
setBatchMode("exit and display");

//exit;
//run("Make Binary");
setThreshold(128,255);

run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing exclude add");

setBatchMode(true);
selectImage(gamma);
run("Close");
selectImage(alpha);
run("Close");
selectImage(beta);
run("Close");
selectImage(forSegmentation);
run("Close");
selectImage(voronoiCells);
run("Close");
selectImage(stackid);
setBatchMode("exit and display");
roiManager("show all"); 
resetThreshold();


if(review==true) {
	waitForUser("Delete improperly segmented cells...");
}

run("Select None");
roiManager("Deselect"); 

//set up the column headers
var columntitles = "\\Headings:filename\troi.id\tslice\tframe\tchannel\trawIntDen";

if (! isOpen("Scores")) {	
	run("New... ", "name=Scores type=Table");
	print("[Scores]", columntitles);
}

run("Set Measurements...", "  integrated display redirect=None decimal=3");
for(i=1;i<=stackchannels;i++){
	Stack.setChannel(i);
	run("Duplicate...", "background removed");
	bgrev=getImageID();
	run("Subtract...", "value="+channelLowerThreshold[i-1]);
	roiManager("Measure"); 
	nr = nResults;
	for (j=0; j<nr; j++){
		print("[Scores]", stackname + "\t" + (j+1) + "\t" + currentslice + "\t" + currentframe + "\t" + "ch" + i + "\t" + getResult("RawIntDen",j));
	}
	run("Clear Results");
	selectImage(bgrev);
	run("Close");
	selectImage(stackid);
}
roiManager("Delete"); 
selectWindow("Results");
run("Close"); 
selectWindow("ROI Manager");
run("Close");
