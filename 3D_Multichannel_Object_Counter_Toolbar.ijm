var nstains = 1;
var initialColors = newArray('red','green','blue','yellow','magenta','orange');
var xs = newArray();
var ys = newArray();
var ss = newArray();
var fs = newArray();
var stains = newArray();
var currentStain = 0;
var nObjects = 0;
var currentColors = Array.copy(initialColors);
var stainMessages = makeStainMenuArray(nstains,currentColors);

var width = 25;
var height = 25;
var objectColor = currentColors[currentStain];
var ghostColor = '444444';
var lineWidth = 1;
setLineWidth(1);

var onionlayers = 1;
var onionskin = true;

var tabletitle = 'Stained Objects';
var columntitles = "\\Headings:ObjectID\tx\t\y\t\z";

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
}

function clickedObject(x,y,z) {
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


function drawObject(x, y, width, height, slice, frame) {
	setColor(objectColor);
   	Overlay.drawEllipse(x-width/2, y-height/2, width, height);
   	if (Stack.isHyperstack==true) {
   		Overlay.setPosition(0,slice,frame);
   	} else {
   		Overlay.setPosition(slice);
   	}
   	Overlay.show();

   	
}

function drawFill(x, y, width, height, slice, frame) {
	setColor(objectColor);
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

function redrawObjects() {
	Overlay.remove();
	//Overlay.clear();
	nObjects=xs.length;
	for (i=0;i<nObjects;i++) {
		drawObject(xs[i], ys[i], width, height, (ss[i]), fs[i]);
		//print(ss[i]+1);
	}
	//Overlay.show();
	//setBatchMode(true);
	for (i=0;i<nObjects;i++) {
			if (getScore(i,currentStain)==1) {
			drawFill(xs[i], ys[i], width, height, (ss[i]), fs[i]);
		}
	}
	//setBatchMode(false);
	Overlay.show();
}

function makeStainMenuArray(nstains,colors) {
	name = newArray();
	for (i=1;i<=nstains;i++) {
		name = Array.concat(name,"Stain"+i+" - "+colors[(i-1) % colors.length]) ;
	}
	return name;
}

macro "Add Object Tool - T3b16+" {
   Stack.getPosition(channel, slice, frame);
   getCursorLoc(x, y, z, flags);
   drawObject(x, y, width, height, slice, frame);
   addObject(x,y,slice,frame);
   nObjects=xs.length;
}

macro "Remove Object Tool - T3b16x" {
	getCursorLoc(x, y, z, flags);
	nObjects=xs.length;
	clicked = clickedObject(x,y,z);
	if (clicked != -1) {
		Overlay.removeSelection(clicked);
		xs = removeElementByIndex(xs, clicked);
		ys = removeElementByIndex(ys, clicked);
		ss = removeElementByIndex(ss, clicked);
		for (j=0;j<nstains;j++) {
			stains = removeElementByIndex(stains, (nstains*clicked));
		}
	}
}

macro "Scorer Tool - Cf55H241777702200C000O00ffO11dd" {
	Stack.getPosition(channel, slice, frame);
	getCursorLoc(x, y, z, flags);
	nObjects=xs.length;
	clicked = clickedObject(x,y,z);
	if (clicked != -1) {
		if (getScore(clicked,currentStain)==0) {
			setScore(clicked,currentStain,1);
			drawFill(xs[clicked], ys[clicked], width, height, (ss[clicked]), frame);
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

macro "Set Number of Stains Action Tool - T2f20n" {
	 Dialog.create("Number of Stains...");
	 Dialog.addNumber("Number of Stains...", nstains);
	 Dialog.addMessage("Warning! Changing this will delete current data.")
	 Dialog.show();
	 nstains = Dialog.getNumber();
	 stainMessages = makeStainMenuArray(nstains,currentColors);
	 deleteAll();
	 
	 //reset the stain menu
}


macro "Scorer Settings Action Tool - T2f24~" {
	 Dialog.create("Object Counter Settings...");
	 
	 Dialog.show();
}

macro "Data Table Action Tool - T3f20#" {
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


macro "Delete All Action Tool - Cf00O00ffO11ddH1221edde" {
	deleteAll();
}
