// Copy LUTs and Min/Max from one multichannel to another

function uniqueTitleToID(uniquetitle) {
	return parseInt(replace(uniquetitle, "^.*\\[ID: ([\\-0-9]+)\\]","$1"));
}

n = nImages;
imageIds = newArray(nImages);
imageTitles = newArray(nImages);
imageUniqueTitles = newArray(nImages);
imageChannels = newArray(nImages);
defaults = newArray(nImages);
copytoIDs = newArray(0);

var devnull = 1;
var nChannels = 1;

for (i=1; i<=n; i++) {
	selectImage(i);
	//Stack.getDimensions(devnull, devnull, nChannels, devnull, devnull);
	imageIds[i-1] = getImageID();
	imageTitles[i-1] = getTitle();
	imageUniqueTitles[i-1] = getTitle() + " [ID: "+getImageID()+"]";
	//imageChannels[i-1] = nChannels;
	defaults[i-1] = false;
}

Dialog.create("Copy Channel Settings");
Dialog.addChoice("Copy from:", imageUniqueTitles, imageTitles[0]);
Dialog.setInsets(0, 0, 0);
Dialog.addMessage("Copy to:");
Dialog.setInsets(0, 20, 0);
Dialog.addCheckboxGroup(nImages, 1, imageUniqueTitles, defaults);
Dialog.show();

copyFromID = uniqueTitleToID(Dialog.getChoice());

for (i=1; i<=n; i++) {
	if (Dialog.getCheckbox()) {
		copytoIDs = Array.concat(copytoIDs,uniqueTitleToID(imageUniqueTitles[i-1]));
	}
}

//print(copyFromID);
//Array.print(copytoIDs);


reds = NaN;
greens = NaN;
blues = NaN;
min = NaN;
max = NaN;
allreds = newArray(0);
allgreens = newArray(0);
allblues = newArray(0);
allminmaxes = newArray(0);

selectImage(copyFromID);
Stack.getDimensions(devnull, devnull, nChannels, devnull, devnull);
Stack.setDisplayMode("color");
for (c = 1; c <= nChannels; c++) {
	Stack.setChannel(c);
	getLut(reds, greens, blues);
	allreds = Array.concat(allreds,reds);
	allgreens = Array.concat(allgreens,greens);
	allblues = Array.concat(allblues,blues);
	getMinAndMax(min, max);
	allminmaxes = Array.concat(allminmaxes,min);
	allminmaxes = Array.concat(allminmaxes,max);
}

for (i = 0; i < lengthOf(copytoIDs); i++) {
	selectImage(copytoIDs[i]);
	Stack.setDisplayMode("color");
	Stack.getDimensions(devnull, devnull, nChannels, devnull, devnull);
	for (c = 1; c <= nChannels; c++) {
		reds = Array.slice(allreds,(c-1)*256,(c)*256);
		greens = Array.slice(allgreens,(c-1)*256,(c)*256);
		blues = Array.slice(allblues,(c-1)*256,(c)*256);
		Stack.setChannel(c);
		setLut(reds, greens, blues);
		setMinAndMax(allminmaxes[(c-1)*2], allminmaxes[((c-1)*2)+1]);
	}
}

