// Script to add antibody catalog numbers to results table
// need to create list_wells and list_abs, each of equal dimensions
// the demo lists apply to the demo data available on the github repo
// github.com/ABIF-McGill/YCharOS_IF_characterization

// Joel Ryan 2024



//plate 46
list_wells = newArray("C02","C04","C06","C03","C05","C07","B02","B03","B04","B05","B06");
list_abs = newArray("Thermo Fisher Scientific_MA524745_1in500","Thermo Fisher Scientific_PA536606_1in1000","Proteintech_27219-1-AP_1in500","Thermo Fisher Scientific_MA524745_1in100","Thermo Fisher Scientific_PA536606_1in50","Proteintech_27219-1-AP_1in100","__media","__cells","__Alexa rb555+dapi","__Alexa M555+dapi","__Dapi");





print(list_wells.length);
print(list_abs.length);

setBatchMode(true);
for (i = 0; i < nResults; i++) {
	well = getResultString("well", i);

	
	for (j = 0; j < list_wells.length; j++) {
		if (well == list_wells[j]) {
			setResult("antibody", i, list_abs[j]);
			
		}
	}

}

 

