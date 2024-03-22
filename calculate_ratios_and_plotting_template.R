library(ggplot2)
library(tidyr)
library(dplyr)
library(gtools)

library(reshape2)



#setwd("")

data <- read.csv('Results_w3_intensities_2024222_0_abNames_cp2_test_plt46.csv')


data$well_scene <- paste(data$well, data$scene, sep="_")


### Data filtering steps - remove objects with saturation, too round, zero values...

# Preprocess data - remove unwanted rows
data <- data %>%
  filter(Min > 0,
         #antibody != 0,
         Circ. < 0.9,
         Max < 40000,
         w1_max < 40000,
         w2_max < 40000,
         w4_max < 40000)
         #!grepl("__", antibody))


#Get rid of unusable wells
#data<-subset(data, data$well != "D02")


#data <- data[!grepl("__", data$antibody),]

# summarise data

summary_ab_scene_data <- data %>%
  group_by(well, scene, celltype) %>%
  #group_by(antibody, celltype) %>%
  summarise(avg = mean(Mean), med = median(Mean), medArea = median(Area), count = length(Area))

summary_ab_scene_data <- subset(summary_ab_scene_data, summary_ab_scene_data$count > 2)


summary_ab_data <- data %>%
  group_by(well, celltype) %>%
  summarise(avg = mean(Mean), med = median(Mean), medArea = median(Area),count = length(Area))



# for ratios: reshape dataframe

summary_ab_data.wide <- dcast(summary_ab_data, well ~ celltype, value.var="med")
summary_ab_data.wide$ratio <- summary_ab_data.wide$green / summary_ab_data.wide$red
summary_ab_scene_data$ab_scene <-  paste(summary_ab_scene_data$antibody, summary_ab_scene_data$scene)
summary_ab_scene_data.wide <- NULL
summary_ab_scene_data.wide <- dcast(summary_ab_scene_data, scene ~ celltype, value.var="med")
summary_ab_scene_data.wide$ab_scene <- paste(summary_ab_scene_data.wide$antibody, summary_ab_scene_data.wide$scene)
summary_ab_scene_data.wide <- subset(summary_ab_scene_data, summary_ab_scene_data$celltype == "green")

temp = subset(summary_ab_scene_data, summary_ab_scene_data$celltype == "red")
summary_ab_scene_data.wide_2 <- summary_ab_scene_data.wide[(summary_ab_scene_data.wide$ab_scene %in% temp$ab_scene),]


temp <- temp[(temp$ab_scene %in% summary_ab_scene_data.wide$ab_scene),]


summary_ab_scene_data.wide_2$MedGreen <- summary_ab_scene_data.wide_2$med
summary_ab_scene_data.wide_2$MedRed <-temp$med
summary_ab_scene_data.wide_2$ratio <- summary_ab_scene_data.wide_2$MedGreen / summary_ab_scene_data.wide_2$MedRed



summary_ab_data_2 <- summary_ab_scene_data.wide_2 %>%
  group_by(well) %>%
  summarise(avgGreen = mean(MedGreen), avgRed = mean(MedRed), ratio = median(ratio),  numCells = sum(count))




ggplot(summary_ab_data_2, aes(well, ratio)) +
  geom_col(color="dark grey",fill="white")+
  geom_jitter(data = summary_ab_scene_data.wide_2, alpha=0.4, width=0.1) +
  geom_text(aes(x = well, y = -0.1, label = round(ratio, digits = 1)), size=3)+
  theme_classic() +
  #ylim(-0.2,4) +
  xlab("")+
  ylab("Antibody intensity ratio (WT / KO)") +
  #scale_y_log10()+
  geom_hline(yintercept = 1, linetype='dotted', col = 'grey') +
  theme(axis.text.x = element_text(angle = 60, vjust =1, hjust=1))+
  theme(plot.margin = margin(70,70,70,70))


