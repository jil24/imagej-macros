var nstains = 1;
var initialColors = newArray('red','green','blue','cyan','yellow','magenta','orange','white','black');
var initialHexes = newArray('#FF0000','#00FF00','#0000FF','#00FFFF','#FFFF00','#FF00FF','#FF9600','#FFFFFF','#000000');
var xs = newArray();
var ys = newArray();
var ss = newArray();
var fs = newArray();
var stains = newArray();
var currentStain = 0;
var nObjects = 0;
var currentColors = Array.copy(initialColors);
var currentHexes = Array.copy(initialHexes);
var stainMessages = makeStainMenuArray(nstains,currentColors);

//flags for mouse clicks
var shift=1;
var ctrl=2; 
var rightButton=4;
var alt=8;
var leftButton=16;
var insideROI = 32; // requires 1.42i or later


var width = 25;
var height = 25;
var objectColor = currentColors[currentStain];
var lineWidth = 1;
setLineWidth(1);

var onionlayers = 3;
var onionskin = true;

var tabletitle = 'Stained Objects';
var columntitles = "\\Headings:ObjectID\tx\t\y\t\z";

//values for DoG spot detector
	//sigma1 = 1 / (1 + √2 ) × d
	//sigma2 = sqrt(2) × sigma1

var dExp = 20;
var qvalCutoff = 1;

//can't beleive this isn't built in
//http://imagej.1557.x6.nabble.com/macro-tip-for-fast-concatenation-of-strings-td3695693.html
function joinArray(array,sep) {
   oldBuffer=String.buffer;
   String.resetBuffer();
   String.append(""+array[0]);
   for(i=1;i<array.length;i++)
     {
       String.append(sep);
       String.append(array[i]);
     }
   str=String.buffer;
   String.resetBuffer();
   String.append(oldBuffer);
   return str;
}

function removeElementByIndex(array, i) {
	new = newArray();
	narray = array.length;
	for (j=0;j<narray;j++){
		if (i != j) {new = Array.concat(new,array[j]);}	
	}
	return new;
}



function index(a, value) { //get an element's index by value, (first occurrence), otherwise -1
      for (i=0; i<a.length; i++)
          if (a[i]==value) return i;
      return -1;
} 

function arrayMean(array) {
	Array.getStatistics(array, min, max, mean, stdDev);
	return mean;
}
function arrayMax(array) {
	Array.getStatistics(array, min, max, mean, stdDev);
	return max;
}
function arrayMin(array) {
	Array.getStatistics(array, min, max, mean, stdDev);
	return min;
}

function removeElementByBinaryArray(array, binaryArray) {
	narray = array.length;
	mean = arrayMean(binaryArray);
	ntodelete = narray * mean;
	newlength = narray - ntodelete;
	new = newArray(newlength);

	j=0;
	for (i=0;i<narray;i++){
		if (binaryArray[i] == 0) {new[j] = array[i];j++;}	
	}
	return new;
}

function getTableEntry(table,row,column) {
	selectWindow(table);
	rows = split(getInfo(), "\n");
	entries = split(rows[row], "\t");
	entry = entries[column+1];
	return entry;
}

function getTableRow(table,row) {
	selectWindow(table);
	rows = split(getInfo(), "\n");
	entries = split(rows[row],"\t");
	return entries;
}

function setTableEntry(table,row,column,value){
	newrow = getTableRow(table,row);
	newrow[column-1]=value;
	newline = joinArray(newrow,"\t");
	newline = "\\Update" + (row-1) + ":" + newline;
	table = "[" + table + "]";
	print(table,newline);
	
}

function addObject(x,y,s,f) {
	xs = Array.concat(xs,x);
	ys = Array.concat(ys,y);
	ss = Array.concat(ss,s);
	fs = Array.concat(fs,f);
	newStains = newArray(nstains);
	newStains = Array.fill(newStains,0);
	stains = Array.concat(stains,newStains);
	if (onionskin==true) {
			drawOnionSkins(xs.length-1);	
	}
}

function clickedObject(x,y) {
	Stack.getPosition(channel, slice, frame);
	diameter = (height+width)/2;
	res = -1;
	for (i=nObjects-1;i>=0;i--) {
   		if(slice == ss[i] && inCircleCenterDiameter(xs[i],ys[i],diameter,x,y)) {
			//bailout, so we only identify the 'topmost'
			res = i; i = -99;
		}
	}
	return res;
}


function inCircleCenterDiameter(cx,cy,diameter,qx,qy) {
	ux = cx-(diameter/2);		uy = cy;
	vx = cx+(diameter/2);		vy = cy;
	px = cx;					py = cy-(diameter/2);
	res = inCircleUVPQ(ux,uy,vx,vy,px,py,qx,qy);
	return res;
}

function inCircleUVPQ(ux,uy,vx,vy,px,py,qx,qy) {
	uxy2 = ux*ux+uy*uy;
	vxy2 = vx*vx+vy*vy;
	pxy2 = px*px+py*py;
	qxy2 = qx*qx+qy*qy;

	//to save myself a lot of work I calculated the laplace expansion of the relevant 4x4 determinant symbolically using SymPy.
	incircledet = (px*qxy2*uy) - (px*qxy2*vy) - (px*qy*uxy2) + (px*qy*vxy2) + (px*uxy2*vy) - (px*uy*vxy2) - (pxy2*qx*uy) + (pxy2*qx*vy) + (pxy2*qy*ux) - (pxy2*qy*vx) - (pxy2*ux*vy) + (pxy2*uy*vx) + (py*qx*uxy2) - (py*qx*vxy2) - (py*qxy2*ux) + (py*qxy2*vx) + (py*ux*vxy2) - (py*uxy2*vx) - (qx*uxy2*vy) + (qx*uy*vxy2) + (qxy2*ux*vy) - (qxy2*uy*vx) - (qy*ux*vxy2) + (qy*uxy2*vx);
	orderdet = (px*uy) - (px*vy) - (py*ux) + (py*vx) + (ux*vy) - (uy*vx);
	//	print(incircledet * orderdet);
	return (incircledet * orderdet < 0);
}


function drawObject(x, y, width, height, slice, frame, color) {
	setColor(color);
   	Overlay.drawEllipse(x-width/2, y-height/2, width, height);
   	if (Stack.isHyperstack==true) { // using this format fails if not a hyperstack
   		Overlay.setPosition(0,slice,frame);
   	} else {
   		Overlay.setPosition(slice); // this fails if it's a hyperstack... dumb.
   	}
   	Overlay.show();

   	
}

function drawFill(x, y, width, height, slice, frame, color) {
	setColor(color);
   	setLineWidth((width+height)/4+1);
   	Overlay.drawEllipse(x-width/4, y-height/4, width/2, height/2);
   	if (Stack.isHyperstack==true) {
   		Overlay.setPosition(0,slice,frame);
   	} else {
   		Overlay.setPosition(slice);
   	}
   	Overlay.show();
   	setLineWidth(lineWidth);
    
}

function clearOverlay() {
		if (nImages() != 0) {
		Overlay.remove();
	}
}

function deleteAll() {
	clearOverlay();
	xs = newArray();
	ys = newArray();
	ss = newArray();
	stains = newArray();
	currentStain = 0;
	nObjects = 0;
}

function setScore(object,stain,score) {
	stains[(object*nstains)+stain] = score;
}

function getScore(object,stain) {
	return stains[(object*nstains)+stain];
}

function namedColorToHex(string) {
	i = index(initialColors,string);
	if (i == -1) {return "#FFFFFF";print("error: unrecognized color name, substituted white")}
	else {
		return initialHexes[i];
	}
}

function hexPad(n) {
    n = toString(n);
    if(lengthOf(n)==1) n = "0"+n;
    return n;
}

function getOnionSkinColors() {
	if (startsWith(objectColor,"#")) {
		color = substring(objectColor,1);
	}
	else {
		color = substring(namedColorToHex(objectColor),1);
	}
	alphaHexes = newArray();
	for (i=1;i<=onionlayers;i++) {
		alphaHexes = Array.concat(alphaHexes,"#" + hexPad(toHex(256/(pow(2, i)))) + color);
	}
	return alphaHexes;
}

function redrawObjects() {
	Overlay.remove();
	nObjects=xs.length;
	for (i=0;i<nObjects;i++) {
		drawObject(xs[i], ys[i], width, height, (ss[i]), fs[i], objectColor);
	}
	for (i=0;i<nObjects;i++) {
			if (getScore(i,currentStain)==1) {
			drawFill(xs[i], ys[i], width, height, (ss[i]), fs[i], objectColor);
		}
	}
	
	Overlay.show();
	if (onionskin==true) {
		for (i=0;i<nObjects;i++) {
			drawOnionSkins(i);
		}	
	}
}

function drawOnionSkins(object) {
		onionSkinColors = getOnionSkinColors();
		Stack.getDimensions(imagewidth, imageheight, nchannels, nslices, nframes);
		
			for (j=1;j<=onionlayers;j++) {
				if (ss[object]-j>0) {
					if (getScore(object,currentStain)==1) {
						drawFill(xs[object], ys[object], (width/pow(2,j))+1, (height/pow(2,j))+1, (ss[object]-j), fs[object], onionSkinColors[j-1]);
					} else {
						drawObject(xs[object], ys[object], width/pow(2,j), height/pow(2,j), (ss[object]-j), fs[object], onionSkinColors[j-1]);
					}
				}
				if (ss[object]+j<=nslices) {
					if (getScore(object,currentStain)==1) {
						drawFill(xs[object], ys[object], (width/pow(2,j))+1, (height/pow(2,j))+1, (ss[object]+j), fs[object], onionSkinColors[j-1]);
					} else {
						drawObject(xs[object], ys[object], width/pow(2,j), height/pow(2,j), (ss[object]+j), fs[object], onionSkinColors[j-1]);
					}	
				}
			}
		
}

function makeStainMenuArray(nstains,colors) {
	name = newArray();
	for (i=1;i<=nstains;i++) {
		name = Array.concat(name,"Stain"+i+" - "+colors[(i-1) % colors.length]) ;
	}
	return name;
}




// functions for the scorer menu button

function dataTable() {
	newcolumntitles = columntitles;
	for (i=1;i<=nstains;i++) {
		newcolumntitles = newcolumntitles+"\tstain"+i;
	}
	if (isOpen(tabletitle)) {
		selectWindow(tabletitle);
		run("Close");
	} 	
	run("New... ", "name=["+ tabletitle +"] type=Table");
	print("[" + tabletitle + "]", newcolumntitles);
	
	for (i=0;i<nObjects;i++) {
		datastring = "" + (i+1) + "\t" + xs[i] + "\t" + ys[i] + "\t" + ss[i];
		for (j=0;j<nstains;j++) {
			datastring = datastring+ "\t" +stains[(nstains*i)+j];
		}
		print("[" + tabletitle + "]",datastring);
	}
}

function configurationWindow() {
	 Dialog.create("Number of Stains...");
	 Dialog.addNumber("Number of Stains...", nstains);
	 Dialog.addMessage("Warning! Changing this will delete current data.")

	 Dialog.addMessage("Display Settings:");
	 Dialog.addNumber("Object diameter:", width);
	 Dialog.addNumber("Outline width:", lineWidth);
	  Dialog.addCheckbox("Draw onion skins:", onionskin);
	  Dialog.addNumber("Number of slices to draw onion skins:", onionlayers);
	 Dialog.show();

	 
	 nstains = Dialog.getNumber();
	 
	 width = Dialog.getNumber();
	 height = width;
	 lineWidth = Dialog.getNumber();
	 setLineWidth(lineWidth);
	
	onionskin = Dialog.getCheckbox();
	onionlayers = Dialog.getNumber();
	 
	 stainMessages = makeStainMenuArray(nstains,currentColors);
	 deleteAll();

	 
	



	 
	 //reset the stain menu
}

function spotDetector() {
	Stack.getPosition(channel, slice, frame);
	im = getImageID(); // this should be changed when the script becomes aware of multiple images

	final = false;

	while (final == false) {
		Dialog.create("Spot Detector");
		Dialog.addSlider("Spot Size...", 1, 50, dExp);
		Dialog.addSlider("Spot Quality Cutoff...", 0.01, 1.99, qvalCutoff);
		Dialog.addCheckbox("Finalize Settings:", false);
		Dialog.show();

		dExp = Dialog.getNumber();
		qvalCutoff = Dialog.getNumber();
		final = Dialog.getCheckbox();

		setBatchMode(true);
		useselection = 0;
		if (selectionType() != -1) {
			useselection = 1;
			run("Create Mask");
			selectImage(im);
			run("Select None");
		}

		rExp = dExp/2;
	
		sigma1 = (1/(1+sqrt(2))*dExp);
		sigma2 = sqrt(2)*sigma1;

		Overlay.clear;
		run("Duplicate...", "title=sigma1");
		run("32-bit");
		run("Gaussian Blur...", "sigma=" + sigma1);
		
		selectImage(im);
		
		run("Duplicate...", "title=sigma2");
		run("32-bit");
		run("Gaussian Blur...", "sigma=" + sigma2);
		
		
		imageCalculator("Subtract create 32-bit", "sigma1","sigma2");
		
		selectWindow("sigma1");
		close();
		selectWindow("sigma2");
		close();

		if (useselection == 1) {
			selectImage("Mask");
			run("Create Selection");
			selectWindow("Result of sigma1");
			run("Restore Selection");
		} else {
			selectWindow("Result of sigma1");
		}
		
		
		run("Min...", "value=0");
		run("Find Maxima...", "noise=0 output=[Point Selection]");
		
		getSelectionCoordinates(xpoints, ypoints);
		run("Select None");
		close();
		


		nspots = xpoints.length;
		 showStatus("" + nspots + " blobs detected, filtering...");
		
		//sort by x coordinate
		indices = Array.rankPositions(xpoints);
		xpoints = Array.sort(xpoints);
		
		sortedypoints = newArray(nspots);
		for (i=0;i<nspots;i++) {
			sortedypoints[i] = ypoints[indices[i]];
		}
		ypoints = sortedypoints;
		
		sigma1values = newArray(nspots);
		sigma2values = newArray(nspots);
		qval = newArray(nspots);
		
		for (i=0;i<nspots;i++) {
			 makeOval(xpoints[i]-sigma1/2, ypoints[i]-sigma1/2, sigma1, sigma1);
			 getStatistics(area, mean);
			 sigma1values[i] = area * mean;
			 s1area = area;
			 
			 makeOval(xpoints[i]-sigma2/2, ypoints[i]-sigma2/2, sigma2, sigma2);
			 getStatistics(area, mean);
			 sigma2values[i] = (area * mean)-sigma1values[i];

			sigma1values[i] = sigma1values[i] / s1area;
			sigma2values[i] = sigma2values[i] / (area - s1area);
			qval[i] = (sigma1values[i]-sigma2values[i])*sigma1values[i];
		
			 run("Select None");
		}

		

		qvmax = arrayMax(qval);
		deletelist = newArray(nspots);
		
		for (i=0;i<nspots;i++) {
			showStatus("Quality filtering... "+i+"/"+nspots);
			qval[i] = qval[i]/qvmax;
			deletelist[i] = (qval[i]<=qvalCutoff);
		}

		if (arrayMean(deletelist)>0) {
			xpoints = removeElementByBinaryArray(xpoints,deletelist);
			ypoints = removeElementByBinaryArray(ypoints,deletelist);
			qval = removeElementByBinaryArray(qval,deletelist);
			
		}
		nspots = xpoints.length;


		//make a new deletelist
		deletelist = newArray(nspots);
		Array.fill(deletelist,0);

		showStatus("" + nspots + " blobs after quality filtering. detecting overlapping blobs...");

		if (useselection == 1) {
			selectImage("Mask");
			run("Create Selection");
			close();
			selectImage(im);
			run("Restore Selection");
		} else {
			selectImage(im);
		}
		
		setBatchMode("exit and display");
		
		for (i=0;i<nspots;i++) {
			showStatus("Detecting overlapping blobs: "+i+"/"+nspots);
			drawObject(xpoints[i], ypoints[i], dExp, dExp, slice, frame, objectColor);
			Overlay.show;
			for (j=i+1;j<nspots;j++) {
				if(i!=j && abs(xpoints[i]-xpoints[j]) < dExp && abs(ypoints[i]-ypoints[j]) < dExp){
					if (inCircleCenterDiameter(xpoints[i],ypoints[i],dExp,xpoints[j],ypoints[j])){
						if (qval[i]>qval[j] && deletelist[i] != 1){
							deletelist[j] = 1;
						} else if (deletelist[j] != 1) {
							deletelist[i] = 1;
							j = nspots; // bail out to i loop
						}
					}
				} else if (xpoints[j]-xpoints[i] >= dExp) {
					//since we're x-sorted, if we've passed the x-distance, we're good - move on.
					j = nspots; // bail out to i loop
				}
			}
		}

		if (arrayMean(deletelist)>0) {
			xpoints = removeElementByBinaryArray(xpoints,deletelist);
			ypoints = removeElementByBinaryArray(ypoints,deletelist);
			qval = removeElementByBinaryArray(qval,deletelist);
			
		}
		
		nspots = xpoints.length;
		
	}

	setBatchMode("exit and display");

	
	for (i=0;i<nspots;i++) {
			if (qval[i]>qvalCutoff) {
				addObject(xpoints[i], ypoints[i], slice, frame);
		}
	}
	redrawObjects();
}


}






macro "Add Object Tool (shift drag moves / shift right drag changes slice) - T3b16+" {
   Stack.getPosition(channel, slice, frame);
   Stack.getDimensions(imagewidth, imageheight, nchannels, nslices, nframes);
   getCursorLoc(x, y, z, flags);
   //print(flags);
   if (flags&shift!=0) {
   	 clicked = clickedObject(x,y);
   	 if (clicked != -1) {
   	   while (flags != 0) {
   	   	 getCursorLoc(x,y,z,flags);
   	   	 xs[clicked] = x;
   	     ys[clicked] = y;
   	     redrawObjects();
   	     wait(25);
   	   }
   	 }
   } else if (flags&rightButton!=0) {
   	//print("bleh");
   	 clicked = clickedObject(x,y);
   	 if (clicked != -1) {
   	 	ox = x;
   	 	oslice = slice;
   	   while (flags != 0) {
   	   	 getCursorLoc(x,y,z,flags);
   	   	 toslice = oslice+floor((x-ox)/15);
   	   	 //print(toslice);
   	   	 if (toslice > nslices) {
   	   	 	toslice = nslices;
   	   	 }
   	   	 if (toslice < 1) {
   	   	 	toslice = 1;
   	   	 }
   	   	 ss[clicked] = toslice;
		 Stack.setPosition(channel,toslice,frame);
   	     redrawObjects();
   	     wait(100);
   	   }
   	   
   	 }
   }
   else {
   	 drawObject(x, y, width, height, slice, frame, objectColor);
   	 addObject(x,y,slice,frame);
   	 nObjects=xs.length;
   }
}

macro "Add Object Tool (shift drag moves / shift right drag changes slice) Selected" {
	setOption("DisablePopupMenu", true); //kludge
	redrawObjects();
}

macro "Remove Object Tool - T3b16x" {
	getCursorLoc(x, y, z, flags);
	nObjects=xs.length;
	clicked = clickedObject(x,y);
	if (clicked != -1) {
		Overlay.removeSelection(clicked);
		xs = removeElementByIndex(xs, clicked);
		ys = removeElementByIndex(ys, clicked);
		ss = removeElementByIndex(ss, clicked);
		for (j=0;j<nstains;j++) {
			stains = removeElementByIndex(stains, (nstains*clicked));
		}
	nObjects=xs.length;
	}
}

macro "Scorer Tool - Cf55H241777702200C000O00ffO11dd" {
	Stack.getPosition(channel, slice, frame);
	getCursorLoc(x, y, z, flags);
	nObjects=xs.length;
	clicked = clickedObject(x,y);
	if (clicked != -1) {
		if (getScore(clicked,currentStain)==0) {
			setScore(clicked,currentStain,1);
			drawFill(xs[clicked], ys[clicked], width, height, (ss[clicked]), frame, objectColor);
			if (onionskin == true) {
			drawOnionSkins(clicked);
			}
		} else {
			setScore(clicked,currentStain,0);
			redrawObjects();
		}
	}
}

macro "Scorer Tool Options" {
}

macro "Cycle Through Stains Action Tool - T2f20>" {
	currentStain = (currentStain+1)%nstains;
	showStatus(stainMessages[currentStain]);
	objectColor = currentColors[currentStain];
	redrawObjects();
}

var menu = newMenu("Scorer Menu Tool", newArray("Data Table","Configuration","","Spot Detector","","Delete All"));

macro "Scorer Menu Tool - T2f20#" {
	cmd = getArgument();
	if (cmd == "Data Table") {
		dataTable();
	}
	if (cmd == "Configuration") {
		configurationWindow();
	}
	if (cmd == "Spot Detector") {
		spotDetector();
	}
	if (cmd == "Delete All") {
		sure = getBoolean("Really delete everything?");
		if (sure == true) {deleteAll();}
	}
}

//macro "Delete All Action Tool - Cf00O00ffO11ddH1221edde" {
//	deleteAll();
//}


//To Do
//-------------
//Save and Load
//mutliptle image window handling
//Count totaling
//Onion skinning
//Options: General options (name stains, specify colors, specify thickness, dot size, dot shape, onionskin thickness)
//Options: non-destructive dimensional addition/contraction
//Autocounting
//Autoscoring
//Menu: Gear
//1: Load...
//2: Save
//3: Save As...
//4:--
//5: Toggle onion skinning
//6:--
//7: Options: General options (name stains, specify colors, specify thickness, dot size, dot shape, onionskin thickness)
//8: Options: non-destructive dimensional addition/contraction