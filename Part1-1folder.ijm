dir1 = getDirectory("Choose Source Directory: ");

input = dir1
output = dir1 + "OUTPUT\\";

list = getFileList(input);

File.makeDirectory(output);

setBatchMode(true);

for (i = 0; i < list.length; i++) {
	filename=list[i];
	L=lengthOf(filename);
	filebase=substring(filename,0,L-4);
	Pengli2(input, filename);
}


function Pengli2(input, filename) {
	open(input+filename);
	run("Z Project...", "projection=[Sum Slices]");
	saveAs("Tiff", output+filebase+"_max.tif");
	run("Close All");
}
