
// Ask Pengli where his files are (FULL Z-STACKS ONLY) and get the list of files:
input = getDirectory("Choose Source Directory: ");
list = getFileList(input);

//Chrisnote: run this line in the command prompt before you start:
// for f in *\ *; do mv "$f" "${f// /_}"; done

// (On Mac: Note chcange czi to file ending you need

//find $1 -name "* *.czi" -type f -print0 | \
//  while read -d $'\0' f; do mv -v "$f" "${f// /_}"; done

//Define where to save the images
output = input + "OUTPUT/";

//Make that folder if it doesn't exist
File.makeDirectory(output);

for (i = 0; i < list.length; i++) {
	filename=list[i];
	PengliCellMask(input, filename);
	}


function PengliCellMask(input,filename){

	//Define the file naming scheme:
	L=lengthOf(filename);
	filebase=substring(filename,0,L-4);

	// Open the image
	run("Bio-Formats", "open=" + input + filename + " autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
	imageID=getTitle();
	run("Duplicate...", "duplicate");
	imageID2=getTitle();
	
	// Make a max intensity projection to choose the mask
	run("8-bit");
	run("Make Composite", "display=Composite");
	run("RGB Color", "slices");
	run("Z Project...", "projection=[Max Intensity]");
	run("Enhance Contrast", "saturated=0.35");
	roiManager("reset");

	//Reset to the point selecting tool and ask Pengli for the center of the nucleus:
	setTool("multipoint");
	waitForUser ( "Center","Choose the center of the nucleus. If you miss, just add another point--it will only keep the last one.");
	roiManager("Add");
	roiManager("Select", 0);
	Roi.getCoordinates(x,y);

	//Ask Pengli to trace the cell
	setTool("polygon");
	waitForUser ( "ROI","Select an ROI");
	roiManager("Add");
	roiManager("Select", 1);
	roiManager("remove slice info");

	//Close the max intensity image
	close();
	selectWindow(imageID2);
	close();
	selectWindow(imageID);

	//Load the ROI, clear the background, and delete the data from outside cells
	roiManager("Select", 1);
	setBackgroundColor(0, 0, 0);
	run("Clear Outside", "stack");

	
	saveAs("Tiff", output+filebase+"_x="+x[x.length-1]+"_y="+y[y.length-1]+".tif");
	run("Close All");
	
}
