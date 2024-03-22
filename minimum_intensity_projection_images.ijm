// helper script - generate Minimum Intensity Projection images from w3.tif target antibody images


input = getDirectory("Choose a source folder");
filelist = getFileList(input);

num_images_per_well = 9;

main_prefix = "Plate";


target_suffix = "w3.TIF";
filelist = Array.filter(filelist, target_suffix);


for (k = 0; k < filelist.length; k++) {

	if (startsWith(filelist[k], main_prefix)) {
		open(input+filelist[k]);
	}

}

run("Images to Stack", "name=Stack title=[] use");

run("Grouped Z Project...", "projection=[Min Intensity] group=" + num_images_per_well);

