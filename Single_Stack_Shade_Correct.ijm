width = 0;
height = 0;
channels = 0;
slices = 0;
frames = 0;

area = 0;
mean = 0;
min = 0;
max = 0;
std = 0;

stack = getImageID();
getDimensions(width, height, channels, slices, frames);

// The first filter works on uneven illumination within single frames
// New image = old image * (average value of old image/blurred old image) 
// the original movie needs to be 16 bit...

for (i=1; i<=slices; i++) {
	selectImage(stack);
	setSlice(i);
	run("Duplicate...", "title=temporary");
	run("32-bit");
	getStatistics(area, mean, min, max, std);
	original = getImageID();
	run("Duplicate...", "title=blurred");
	blurred = getImageID();
	run("Gaussian Blur...", "sigma=100");
	run("Reciprocal");
	run("Add...", "value=" + mean);
	imageCalculator("Multiply create", "original","blurred");
	adjusted = getImageID();
	run("16-bit");
	run("Copy");
	selectImage(stack);
	run("Paste");
	
	selectImage(original);
	close();
	selectImage(blurred);
	close();
	selectImage(adjusted);
	close();
	
	//free up memory!
	call("java.lang.System.gc");
}
