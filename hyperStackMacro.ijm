stackid = getImageID();
var stackwidth = 1;
var stackheight = 1;
var stackchannels = 1;
var stackslices = 1;
var stackframes = 1;
Stack.getDimensions(stackwidth, stackheight, stackchannels, stackslices, stackframes);

var currentchannel = 1;
var currentslice = 1;
var currentframe = 1;

Stack.getPosition(currentchannel, currentslice, currentframe);

Dialog.create("do a macro to a hyperstack:");
	Dialog.addMessage("do the thing on every:");
	Dialog.addCheckbox("channel", false);
	Dialog.addCheckbox("slice", false);
	Dialog.addCheckbox("frame", false);
	Dialog.addMessage("Run a macro:");
	Dialog.addString("Filename (in macros folder) or leave blank for fileselector", "")
	
	Dialog.show();
	dochannels=Dialog.getCheckbox();
	doslices=Dialog.getCheckbox();
	doframes=Dialog.getCheckbox();
	filename=Dialog.getString();

//iterate if desired, otherwise stay on current coordinate
minchannel=currentchannel;
maxchannel=currentchannel;
minslice=currentslice;
maxslice=currentslice;
minframe=currentframe;
maxframe=currentframe;

if(filename=="") {filename=File.openDialog("Select a Macro File"); ;}

if (dochannels==true) {
	minchannel=1;
	maxchannel=stackchannels;
	}

if (doslices==true) {
	minslice=1;
	maxslice=stackslices;
	}

if (doframes==true) {
	minframe=1;
	maxframe=stackframes;
	}

for (c=minchannel;c<=maxchannel;c++) {
	Stack.setChannel(c);
	for (s=minslice;s<=maxslice;s++) {
		Stack.setSlice(s);
		for (f=minframe;f<=maxframe;f++) {
			print("c"+c+"s"+s+"f"+f);
			Stack.setFrame(f);
			runMacro(filename);
			selectImage(stackid);
		}
	}
}
