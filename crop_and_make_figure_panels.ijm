// Helper script - cropping images 
// github.com/ABIF-McGill/YCharOS_IF_characterization
// IMX images


input = getDirectory("Choose a source folder");
filelist = getFileList(input);



target_prefix = "stack_and_outlines";



filelist = Array.filter(filelist, target_prefix);


// to look for a specific well, or just one image per well, uncomment and edit the following lines as needed
//filelist = Array.filter(filelist, "_D03");
//filelist = Array.filter(filelist, "_s1");

for (k = 0; k < filelist.length; k++) {

	
	if (endsWith(filelist[k], ".tif")) {

		open(input + filelist[k]);
		title = getTitle();
	
		
		resetMinAndMax();
		
		run("Enhance Contrast", "saturated=0.10");
		Stack.setActiveChannels("000011");
		wait(100);
		Stack.setActiveChannels("100011");
		wait(200);
		Stack.setActiveChannels("000011");
		wait(100);
		Stack.setActiveChannels("010011");
		wait(200);
		Stack.setActiveChannels("000011");
		wait(100);
		Stack.setActiveChannels("000111");
		wait(200);
		Stack.setActiveChannels("000011");
		wait(100);
		Stack.setActiveChannels("001011");
		//wait(200);
		//Stack.setActiveChannels("1110");
		

        makeRectangle(1, 1, 250, 125);
        waitForUser("Make a box to crop the image - press shift to skip this image ");

		if (isKeyDown("shift")) {
			     print("The following image was not great: " +title);
			     run("Close All");
         
		 } else {
		 	print(filelist[k]);
		 	roiManager("reset");
		 	roiManager("Add");
		 	roiManager("Save",input+ "cropROI" + title + ".zip");

		 	numROI = roiManager("count");
		 	roiManager("select", numROI-1);
		 	run("Duplicate...", "duplicate");
		 	cropped_image = getImageID();
		 	
		 	
		 	Stack.setActiveChannels("001011");
		 	Stack.setChannel(3);
		 	run("Enhance Contrast", "saturated=0.35");
		 	
		 	waitForUser("adjust contrast for ab image");
		 	
		 	saveAs("tiff", input + "_cropped_stack" + title);
		 	run("RGB Color");
		 	saveAs("tiff", input + "_cropped_stack_ab_RGB" + title);
		 	close();
		 	selectImage(cropped_image);
		 	Stack.setActiveChannels("100011");
		 	Stack.setChannel(1);
		 	
		 	run("Enhance Contrast", "saturated=0.35");
		 	waitForUser("adjust contrast for DAPI");
		 	run("RGB Color");
		 	saveAs("tiff", input + "_cropped_stack_DAPI_RGB" + title);
		 	
		 	run("Close All");
		 	
		 }

	
	}
	}


