// Autofocus hyperstack macro
// Select the in focus frame from each slice of a hyperstack and create a new stack
// of just the in focus frames

// Based on algorithm F-11 "Normalized Variance"
// In: Sun et al., 2004. MICROSCOPY RESEARCH AND TECHNIQUE 65, 139–149.
// And the original macro by Andy Weller http://imagejdocu.tudor.lu/doku.php?id=macro:normalized_variance
// Revisions by Richard Mort 27/09/2018
// Further revised by Jon Lake to handle multichannel hyperstacks with one channel selected as reference 20220513;

setBatchMode(true);

//Get image type
type = bitDepth();
if (type==8) {type="8-bit";} else {if(type==16) {type="16-bit";} else{if(type==32) {type="32-bit";} else {if(type==24) {type="RGB";}}}}

StackID=getTitle();
Stack.getDimensions(width, height, channels, slices, frames);
c=Array.getSequence(channels+1);
c=Array.deleteIndex(c, 0);

if (channels>1) {
		Dialog.create("Hyperstack Autofocus");
		Dialog.addChoice("Channel to focus:", c);
		Dialog.show();
		c = Dialog.getChoice();
	
	} else{}



for (k=1; k<=frames; k++) { Stack.setFrame(k);
	Stack.setChannel(c);
	m=0;
	normVar = 0; // Set to 0 which is out of focus
		for (l=1; l<=slices; l++){ 
			selectWindow(StackID);
			Stack.setSlice(l);
	
	getRawStatistics(nPixels, mean);
	W = getWidth();
	H = getHeight();
	b = 0;
	
	for (j=0; j<H; j++) {
	   for (i=0; i<W; i++) {
	      p = getPixel(i,j);
	      t = (p-mean)*(p-mean);
	      b += t;
	      }
	   }
	
	if ((b/(H*W*mean))>normVar) {normVar = (b/(H*W*mean)); m++;} else {normVar=normVar;}
	
		}Stack.setSlice(l);
	
	for (cc=1;cc<=channels;cc++) {
		Stack.setChannel(cc);
		Stack.setSlice(m);
		run("Select All");
		run("Copy");
		if (isOpen("Output")){
		                selectWindow("Output");
		                if (cc == 1) {run("Add Slice", "add=frame");};
		            }
		            else{
		                //newImage("Output", type, width, height, 1);
		                newImage("Output", type, width, height, channels, 1, 1);
		            }
		Stack.setFrame(k);
		Stack.setChannel(cc);
		run("Paste");
		selectWindow(StackID);
		Stack.setSlice(l);
	}
}
setBatchMode("exit and display");
