// main data extraction and analysis script
// github.com/ABIF-McGill/YCharOS_IF_characterization
// Joel Ryan 2024



// CHOOSE FOLDER! 
// needs raw images and cellpose masks

run("Clear Results");

print("----------------------------------------------------");

run("Set Measurements...", "area mean standard modal min centroid shape median stack display redirect=None decimal=3");


input = getDirectory("Choose a source folder");

// choose raw image prefix... the first few characters for all raw image filenames... often "Plate" or "YCharOS". (all processed images will have different prefixes, except cellpose masks, which end in "cp_masks.png")

raw_image_prefix = "Plate";


// STEP 1: MAKE BINARY MASKS

filelist = getFileList(input);

filelist = Array.filter(filelist, "filtered_cp_masks.png");



wells = newArray();


setBatchMode(true);
for (k = 0; k < filelist.length; k++) {
	open(input+filelist[k]);
	wells = Array.concat(wells, substring(filelist[k],  0, filelist[k].length - 28)); //modded for "_filtered_cp_masks" extension

    setThreshold(1, 65535);
    setOption("BlackBackground", false);
	run("Convert to Mask");
	//binary_green_cells = getImageID();
	//saveAs("tiff", input + "binary_masks_"+ substring(filelist[k], 0 , filelist[k].length - 13));
	saveAs("PNG", input + "binary_masks_"+ substring(filelist[k], 0 , filelist[k].length - 22));
	close();
		
	
}

run("Collect Garbage");




// STEP 2: MAKES MASKS + OUTLINES, REMOVE OVERLAP BETWEEN GREEN AND RED CELL MASKS
// 

filelist = getFileList(input);


//folder of binary masks only - for w2 and w4

suffix = "w2.png";
prefix = "binary_masks_";
filelist = Array.filter(filelist, suffix)
filelist = Array.filter(filelist, prefix)
Array.print(filelist);

for (k = 0; k < filelist.length; k++) {
	open(input + filelist[k]);
	green_masks = getImageID();
	
	red_mask_filename = substring(filelist[k], 0, filelist[k].length - suffix.length) + "w4.png";
	open(input + red_mask_filename);
	red_masks = getImageID();
	
	imageCalculator("AND create", green_masks,red_masks);

	run("Dilate");
	overlap_img = getImageID();
	
	imageCalculator("Subtract create", green_masks, overlap_img);
	
	saveAs("PNG", input+"green_masks_filtered_" + filelist[k]);
	
	run("Analyze Particles...", "size=275-Infinity show=[Bare Outlines]");
	run("Invert");
	green_filt_outlines = getImageID();
	
	saveAs("PNG", input+"green_outlines_filtered_" + filelist[k]);
	
	imageCalculator("Subtract create", red_masks, overlap_img);
	
	saveAs("PNG", input+"red_masks_filtered_" + filelist[k]);
	
	run("Analyze Particles...", "size=275-Infinity show=[Bare Outlines]");
	run("Invert");
	red_filt_outlines = getImageID();
	
	saveAs("PNG", input+"red_outlines_filtered_" + filelist[k]);
	
	
	run("Close All");
	
}



// STEP 3: MAKE MIN PROJECTION OF W3 FOR BG SUB

// BG with well median projection

filelist = getFileList(input);

//filelist = Array.filter(filelist, ".tif");
target_suffix = "w3.TIF";
filelist = Array.filter(filelist, target_suffix);


for (k = 0; k < filelist.length; k++) {
	if (startsWith(filelist[k], raw_image_prefix)) {
		open(input+filelist[k]);
	}

}

run("Images to Stack", "name=Stack title=[] use");

run("Z Project...", "projection=[Min Intensity]");

saveAs("Tiff", input + "MIN_Stack_w3.tif");
run("Close All");


// STEP 3.2: MAKE Min projection of w1 for BG SUB of dapi images

filelist = getFileList(input);


target_suffix = "w1.TIF";
filelist = Array.filter(filelist, target_suffix);


for (k = 0; k < filelist.length; k++) {
	if (startsWith(filelist[k], raw_image_prefix)) {
		open(input+filelist[k]);
	}

}

run("Images to Stack", "name=Stack title=[] use");

run("Z Project...", "projection=[Min Intensity]");

saveAs("Tiff", input + "MIN_Stack_w1.tif");
run("Close All");



// STEP 4: MAKE STACKS WITH RAW IMAGES AND CELLMASK OUTLINES, SUBTRACT BG ON W3, ADJUST LUTs

filelist = getFileList(input);


suffix = "w1.TIF";


filelist = Array.filter(filelist, suffix);

green_img_suffix = "w2.TIF";
ab_img_suffix = "w3.TIF";
red_img_suffix = "w4.TIF";

green_outlines_prefix = "green_outlines_filtered_binary_masks_"
green_outlines_suffix = "w2.png";



red_outlines_prefix = "red_outlines_filtered_binary_masks_";
red_outlines_suffix = "w2.png"; // weird from previous macro :/


print("--------------------------");
Array.print(filelist);




for (k = 0; k < filelist.length; k++) {

	
	if (startsWith(filelist[k], raw_image_prefix)) {
	
	//open DAPI image
	open(input + filelist[k]);
	
	
	// open green cells
	green_img_filename = substring(filelist[k], 0, filelist[k].length - suffix.length) + green_img_suffix ;
	open(input + green_img_filename);
	
	
	print("check 01");
	wait(10);
	// open bg image for ab channel
	
	open(input + "bg_baseline.tif");
	
	min_image = getImageID();
	run("Duplicate...", " ");
	bg_to_scale = getImageID();
	bg_med = getValue("Median");
	wait(10);
	
	

	//open binary images
	binary_01 = substring(filelist[k], 0, filelist[k].length - suffix.length) + green_outlines_suffix ;
	print(binary_01);
	binary_01 = "green_masks_filtered_binary_masks_" + binary_01;
	
	open(input + binary_01);
	masks_green_forBG = getImageID();
	
	binary_02 = substring(filelist[k], 0, filelist[k].length - suffix.length) + red_outlines_suffix;
	binary_02 = "red_masks_filtered_binary_masks_"  + binary_02;
	open(input + binary_02);
	masks_red_forBG = getImageID();
	
	
	imageCalculator("Add create", masks_green_forBG, masks_red_forBG);
	
	cp_masks = getImageID();
	
	//open raw ab file. maybe check for saturation...
	ab_img_filename = substring(filelist[k], 0, filelist[k].length - suffix.length) + ab_img_suffix ;
	open(input + ab_img_filename);
	
	
	
	raw_w3 = getImageID();

	
	
	run("Median...", "radius=0.5");
	run("Gaussian Blur...", "sigma=0.5");

	getStatistics(area, mean, min, max, std, histogram);
	if (max > 65000) {
		print(ab_img_filename + "  --  check for saturation");
	}
	
	run("Duplicate...", " ");
	setAutoThreshold("Default dark");
	run("Convert to Mask");
	otsu_thresh = getImageID();
	imageCalculator("Add create", otsu_thresh, cp_masks);
	run("16-bit");
	run("Multiply...", "value=1000");
	all_masks=getImageID();
	
	selectImage(raw_w3);
	run("Duplicate...", " ");
	raw_w3_dup = getImageID();
	
	
	imageCalculator("Subtract", raw_w3_dup, all_masks);
	setThreshold(1, 65535);
	
	// setThreshold and limit to threshold
	img_med = getValue("Median limit");
	
	scalar = (img_med / bg_med);
	
	
	
	
	selectImage(bg_to_scale);
	run("Multiply...", "value="+ (0.95 * scalar));
	
	imageCalculator("Subtract", raw_w3, bg_to_scale);
	saveAs("tiff", input + "bg_sub_" + filelist[k]);
	
	wait(10);
	
	selectImage(min_image);
	close();
	selectImage(bg_to_scale);
	close();
	selectImage(raw_w3_dup);
	close();
	selectImage(masks_green_forBG);
	close();
	selectImage(masks_red_forBG);
	close();
	selectImage(all_masks);
	close();
	selectImage(cp_masks);
	close();
	selectImage(otsu_thresh);
	close();
	
	
	red_img_filename = substring(filelist[k], 0, filelist[k].length - suffix.length) + red_img_suffix ;
	open(input + red_img_filename);
	
		
	
	//dapi_masks_filename = 
		
	print("check 02");
		
	green_outlines_filename = green_outlines_prefix + substring(filelist[k], 0, filelist[k].length - suffix.length) + green_outlines_suffix;
	print(green_outlines_filename);
	open(input+green_outlines_filename);
	
	red_outlines_filename = red_outlines_prefix + substring(filelist[k], 0, filelist[k].length - suffix.length) + red_outlines_suffix;
	print(red_outlines_filename);
	open(input+red_outlines_filename);
	
	run("Images to Stack", "name=Stack title=[] use");
	
	run("Properties...", "channels="+nSlices+" slices=1 frames=1 pixel_width=1 pixel_height=1 voxel_depth=1.0000000");
	
	run("Make Composite", "display=Composite");
	Stack.setChannel(1);
	run("Grays");
	Stack.setChannel(2);
	run("Green");
	Stack.setChannel(3);
	run("Grays");
	run("Enhance Contrast", "saturated=0.35");
	Stack.setChannel(4);
	run("Magenta");
	Stack.setChannel(5);
	run("Green");
	Stack.setChannel(6);
	run("Magenta");
	Stack.setActiveChannels("001011");
	
	
	saveAs("tiff",input + "stack_and_outlines_" + substring(filelist[k], 0,  filelist[k].length - suffix.length));
	close();
	

}
}

run("Collect Garbage");



// STEP 6: MEASURE INTENSITIES OF W3 WITHIN MASKS


roiManager("reset");
run("Clear Results");

filelist = getFileList(input);


//folder of binary masks only - for w2 and w4

prefix = "bg_sub_";
suffix = "w3.tif";
filelist = Array.filter(filelist, prefix)




//    GET INTENSITY FROM OTHER CHANNELS, STORE ON SAME LINE!... OPEN OTHER IMAGE, SELECT ROI, GET STATS, SETRESULT... 


for (k = 0; k < filelist.length; k++) {

	
	open(input + filelist[k]);
	ab_img = getImageID();
	run("Enhance Contrast", "saturated=0.35");
	
	green_mask_filename = "green_masks_filtered_binary_masks_" + substring(filelist[k], prefix.length, filelist[k].length - suffix.length) + "w2.png";
	
	open(input + green_mask_filename);
	green_masks = getImageID();
	
	roiManager("reset");
	run("Analyze Particles...", "size=250-Infinity add");
	
	numROI = roiManager("count");
	
	well = substring(filelist[k], filelist[k].length - 13, filelist[k].length - 10);
	
	scene = substring(filelist[k], filelist[k].length - 9, filelist[k].length - 7);
	
	w1_filename = substring(filelist[k], prefix.length, filelist[k].length - suffix.length) + "w1.TIF";
	open(input + w1_filename);
	wait(10);
	w1_img = getImageID();
	
	w2_filename = substring(filelist[k], prefix.length, filelist[k].length - suffix.length) + "w2.TIF";
	open(input + w2_filename);
	wait(10);
	w2_img = getImageID();
	
	w4_filename = substring(filelist[k], prefix.length, filelist[k].length - suffix.length) + "w4.TIF";
	open(input + w4_filename);
	wait(10);
	w4_img = getImageID();
	
	

	
	for (i = 0; i < numROI; i++) {
		selectImage(ab_img);
		roiManager("select", i);
		run("Measure");
		setResult("celltype", nResults-1, "green");
		setResult("well", nResults-1, well);
		setResult("scene", nResults-1, scene);
		
		selectImage(w1_img);
		roiManager("select", i);
		getStatistics(area, mean, min, max, std, histogram);
		setResult("w1_mean", nResults-1, mean);
		setResult("w1_max", nResults-1, max);
		
		selectImage(w2_img);
		roiManager("select", i);
		getStatistics(area, mean, min, max, std, histogram);
		setResult("w2_mean", nResults-1, mean);
		setResult("w2_max", nResults-1, max);
		
		selectImage(w4_img);
		roiManager("select", i);
		getStatistics(area, mean, min, max, std, histogram);
		setResult("w4_mean", nResults-1, mean);
		setResult("w4_max", nResults-1, max);
		
		
	}

	

	
	red_mask_filename = "red_masks_filtered_binary_masks_" + substring(filelist[k], prefix.length, filelist[k].length - suffix.length) + "w2.png";
	
	open(input + red_mask_filename);
	red_masks = getImageID();
	roiManager("reset");
	run("Analyze Particles...", "size=250-Infinity add");
	
	numROI = roiManager("count");
	
	for (i = 0; i < numROI; i++) {
		selectImage(ab_img);
		roiManager("select", i);
		run("Measure");
		setResult("celltype", nResults-1, "red");
		
		setResult("well", nResults-1, well);
		setResult("scene", nResults-1, scene);
		
		selectImage(w1_img);
		roiManager("select", i);
		getStatistics(area, mean, min, max, std, histogram);
		setResult("w1_mean", nResults-1, mean);
		setResult("w1_max", nResults-1, max);
		
		selectImage(w2_img);
		roiManager("select", i);
		getStatistics(area, mean, min, max, std, histogram);
		setResult("w2_mean", nResults-1, mean);
		setResult("w2_max", nResults-1, max);
		
		selectImage(w4_img);
		roiManager("select", i);
		getStatistics(area, mean, min, max, std, histogram);
		setResult("w4_mean", nResults-1, mean);
		setResult("w4_max", nResults-1, max);
	}
	
	run("Close All");
	
}



//save results table

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

filelist = getFileList(input);
filelist = Array.filter(filelist, "Results_w3_intensities_");
num_results_files = toString(filelist.length);
saveAs("Results", input+"Results_w3_intensities_" + toString(year) + toString(month) + toString(dayOfMonth) + "_" + num_results_files + ".csv");







