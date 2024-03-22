import torch
import os
import glob
import time
from datetime import datetime
import numpy as np
from scipy import ndimage
from PIL import Image
from skimage import io, morphology
from cellpose import models, io



class CellposeImageProcessor:
    def __init__(self, folder_path, diam_run, model_run, suffix, masks_suffix, new_suffix):
        self.folder_path = folder_path
        self.diam_run = diam_run
        self.model_run = model_run
        self.suffix = suffix
        self.masks_suffix = masks_suffix
        self.new_suffix = new_suffix

    def process_images(self):
        path = os.path.join(self.folder_path, self.suffix)
        files = glob.glob(path)
        print(files)

        start_time = time.time()
        current_date_time = datetime.now()

        print("Start time: " + str(current_date_time))
        print("GPU available: " + str(torch.cuda.is_available()))
        print(torch.cuda.get_device_name(0))

        files = sorted(files)

        print(path)
        print("Number of files: " + str(len(files)))
        print("Model: " + self.model_run)
        print("Diameter: " + str(self.diam_run))

        imgs = [io.imread(f) for f in files]
        sub_files = files

        model = models.Cellpose(gpu=True, model_type=self.model_run)
        channels = [0, 0]
        masks, flows, styles, diams = model.eval(imgs, diameter=self.diam_run, augment=True, batch_size=2,
                                                 flow_threshold=None, channels=channels, do_3D=False, interp=False,
                                                 resample=True, progress=True)

        print("runtime: %s seconds ---" % (time.time() - start_time))
        print("Saving masks...")
        io.save_to_png(imgs, masks, flows, sub_files)
        print("Masks saved")
        time.sleep(3)

    def generate_binary_masks(self):
        print('Generating binary masks - removing outline, filtering small objects')

        filter_diameter_scalar = 0.6
        masks_folder = os.path.join(self.folder_path, self.masks_suffix)
        masks_images = glob.glob(masks_folder)

        for img in masks_images:
            print(img)
            img_read = io.imread(img)
            img_2 = img_read * (np.abs(ndimage.laplace(img_read)) > 0)
            img_3 = img_read - img_2
            filtered_img = morphology.remove_small_objects(img_3, min_size=(self.diam_run * filter_diameter_scalar) ** 2)
            im = Image.fromarray(filtered_img)
            img_filename_base = (img[0:len(img) - (len(self.masks_suffix)-1)])
            new_img_filename = img_filename_base + self.new_suffix
            im.save(new_img_filename)

if __name__ == "__main__":
    folder_path = r"Z:\data2\BrownLab\joel.ryan\IMX\Plate46_Rab5C_11617\Plate46 Rab5C_Plate_11617\duplicate_raw_images"
    diam_run = 35
    model_run = 'cyto'
    suffix = r"*w[2,4].TIF"


    masks_suffix = "*_cp_masks.png"
    new_suffix = "_filtered_cp_masks.png"

    processor = CellposeImageProcessor(folder_path, diam_run, model_run, suffix, masks_suffix, new_suffix)
    processor.process_images()
    processor.generate_binary_masks()

