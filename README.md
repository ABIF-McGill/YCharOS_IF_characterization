# YCharOS_IF_characterization
A pipeline to analyze IF images for antibody characterization

The experimental approach is described in [Scaling of an antibody validation procedure enables quantification of antibody performance in major research applications](https://elifesciences.org/articles/91645)


In a recently submitted follow up manuscript, we use quantitative image analysis to measure antibody labeling efficacy for immunofluorescence (IF) labeling. The outline, demo images, and scripts are contained within this repository. 


## Background
The following is a general approach to quantifying antibody labeling efficacy in the context of immunofluorescence labeling. 

First, for a given target, a cell line in which the target protein has been genetically knocked out is required, along with the control cell line in which target expression is affected. For example, to test the efficacy of an antibody against the protein TCM2, one would need a TCM2 knockout cell line (here referred to as KO cells), as well as the parental cell line in which TCM2 expression is unaffected (here referred to as WT cells), in order to have comparable cellular backgrounds. Samples are prepared by labelling WT cells with Cell Mask Green, and KO cells with Cell Mask Red, and then co-culturing labelled WT and KO cells in the same dish or wells. Since IF experiments are prone to experimental variability, given the multi-step nature of these protocols, co-culturing drastically minimizes discrepancies in labeling efficiency due to accuracy limits of equipment and steps as well as manipulation errors.

To test multiple antibodies against a given target, a mix of WT and KO cells for a given target are grown in glass bottom 96-well plates. Each well, containing WT and KO cells, is processed for IF with a test antibody and labeled with a secondary antibody conjugated to AlexaFluor-568, are stained with DAPI. The plate is then imaged on a high-content fluorescence microscope such as the ImageXpress. Four channel fluorescence images are acquired for each well, in order to collect images from DAPI, Cell Mask Green, AlexaFluor-568, and Cell Mask Red. Each channel is saved as a separate image file (.tif), all files for a given plate are saved in one folder. 

Each image set contains the name of the plate (e.g. "Plate_61_TGM2_"), the coordinates of the well (e.g. "C09"), and a suffix corresponding to the channel: 
* "_w1" for DAPI
* "_w2" for Cell mask Green (indicating WT cells)
* "_w3" for AlexaFluor-568  (test antibody labeling)
* "_w4" for Cell mask Red (indicating KO cells)


In the folder "Main_IMX_analysis_scripts", there are the scripts used for analysis of all antibodies tested to date by YCharOS, which absolutely require the file format described above. We will generate amended scripts to make it more accessible to users with different file formats. 


## Main steps

### Cell segmentation

The analysis pipeline generally works as follows. First, the Cell mask channels are segmented, in order to find objects which specifically correspond to WT or KO cells. In our case, we use Cellpose (Stringer et al 2020), as it has reliably detected cultured cells labeled with cell mask in the varying conditions associated with multi-well plate processing and imaging. To batch process all WT ("_w2") and KO ("_w4") images within a folder, we used a batch processing script in Python, allowing to sequentially run Cellpose on each image. 

Cellpose output images are PNG, with the original filename + the suffix "_cp_masks".

After segmentation, and within the same script, we reload each "cp_mask" image and run an erode function on each mask, and save a new set of corresponding images with the suffix "filtered_cp_masks". 

These filtered mask images are then imported into Fiji. In these images, masks are labeled, in that they each have an individual pixel value corresponding ranging from 1 to the total number of masks detected. To help with downstream processing, we generate binary masks in Fiji, by converting to 255 all pixels with a value above 0. This makes it easier to use these masks with functions such as "Analyze Particles" and most selection functions.





### Background subtraction

Background subtraction is required for quantitative analysis of images, especially widefield images collected on a camera. Cameras inherently have a background grey value much higher than 0, and IF experiments, especially in multiwell plates, are quite susceptible to well-to-well variation in background intensity, which makes comparing intensity ratios slightly difficult.

Background subtraction can be reasonably carried out in many ways. In our case, since there is variable background fluorescence which can be due to unspecific binding of the antibody to the surface of the well, or the presence of debris, we have worked out the following method. 

First we determine a "reasonable" estimated background to include the optical asymmetries between different areas of the image (e.g. corners are usually dimmer than the centre of the image, and on our particular system the lower part of the image is slightly brighter than the top). To do this, in Fiji, we generate a stack containing only images of the test antibody channel ("_w3"). Then we generate a collection of minimum intensity projection images for each well - in our case, we collect 9 image sets per well, and so we make a minimum intensity projection with all nine images per well. We then select a minimum intensity projection images that appear to not have any cellular material in them, and are an adequate visual represenatation of the background in most images. Usually, this comes from a well with images containing fewer cells (thus more "background area") and with minimal debris and minimal bright fluorescent material outside the cells. While an empty well can be used for this, in our hands, this didn't always lead to the best representation of the background, since the is no fluorescent signal accounting for the brightness asymmetries in different areas of the image. 

While this is a manual step requiring human intervention, in the context of a multiwell plate image with a high content system, it has generally allowed for more robust background subtraction, requiring less well-specific or image-specific intervention further down the pipeline. If imaging only a small number of wells or slides, and testing few antibodies, then more common background subtraction procedures, such a local rolling-ball background subtraction, or acquiring background images on different areas of the slide/dish, may be easier and fully applicable.


Once this background image is selected  we save it as a separate image file and we calculate its median pixel intensity value. We will use it by scaling its intensity with an estimated scalar determined from each test antibody image ("_w3"). For each image, we generate an Otsu thresholded binary image, and merge that image with the binary masks image generated from the Cellpose masks image. In this merged binary image, all pixels with a value of 255 should correspond to fluorescent signal, whereas all pixels with a value of 0 should corresponding to the background of this particular image. We then measure the median of the background area of this image







