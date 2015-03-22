//image 1 is selected

image1 = getTitle();
run("Make Composite");
run("Put Behind [tab]");
//image 2 active
image2 = getTitle();
run("Make Composite");
//slice 1 active, align it

setBatchMode(true);
run("Align Image by line ROI", "source=[" + image2 + "] target=[" + image1+ "]");
run("8-bit");
rename("red");
red = getTitle();

//advance both images to slice 2, align
selectWindow(image1);
run("Next Slice [>]");

selectWindow(image2);
run("Next Slice [>]");

run("Align Image by line ROI", "source=[" + image2 + "] target=[" + image1+ "]");
run("8-bit");
rename("green");
green = getTitle();

//advance both images to slice 3, align
selectWindow(image1);
run("Next Slice [>]");

selectWindow(image2);
run("Next Slice [>]");

run("Align Image by line ROI", "source=[" + image2 + "] target=[" + image1+ "]");
run("8-bit");
rename("blue");
blue = getTitle();


//add slices containing the green and blue components

run("Concatenate...", "stack1=["+ red +"] stack2=[" + green + "] title=Aligned");
run("Concatenate...", "stack1=Aligned stack2=[" + blue + "] title=Aligned");

//merge it

run("Stack to RGB");

selectWindow(image1);
run("Stack to RGB");
image1new = getTitle();
selectWindow(image1);
close();
selectWindow(image1new);
rename(image1);


selectWindow(image2);
run("Stack to RGB");
image2new = getTitle();
selectWindow(image2);
close();
selectWindow(image2new);
rename(image2);

selectWindow("Aligned");
close();

setBatchMode("exit and display");
