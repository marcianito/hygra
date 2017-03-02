#' @title plot irrigated water volume per layer and timestep
#'
#' @description test
#'
#' @param test
#' @param test
#' @param test
#' ...
#' @details missing
#' @references Marvin Reich (2016), mreich@@gfz-potsdam.de
#' @examples missing

plotInfWater <- function(filein, plotvar, showlegend = T){
  library(viridis)
  switch(plotvar,
        valuesum = {
                   data_plot = dplyr::group_by(filein, Timestep, zgrid) %>%
                   dplyr::summarize(value = sum(value, na.rm = T))
                   },
        means = {
                   data_plot = dplyr::group_by(filein, Timestep, zgrid) %>%
                   dplyr::summarize(value = mean(value, na.rm = T))
                   },
        theta = {
                   data_plot = dplyr::group_by(filein, Timestep, zgrid) %>%
                   dplyr::summarize(value = max(value, na.rm = T))
                   }
  )
  # legend !?
  if(showlegend){ leg = "right"
  }else{ leg = "none"}
  # maximal vertical extent
  maxy = max(data_plot$zgrid, na.rm=T)
  # miny = max(data_plot$zgrid, na.rm=T)
  # actual plotting
  data.gg = ggplot(data_plot, aes(x = Timestep, y = zgrid)) + geom_raster(aes(fill = value)) + ylim(maxy,0) + 
            theme(legend.position=leg) +
            ylab("Depth [m]") + xlab("Timestep [min]") + 
            scale_fill_gradientn(colours = rev(viridis(7)))
  return(data.gg) 
}

#' @title check infiltrated water volumen
#'
#' @description test
#'
#' @param test
#' @param test
#' @param test
#' ...
#' @details missing
#' @references Marvin Reich (2016), mreich@@gfz-potsdam.de
#' @examples missing

checkWaterVolumes <- function(filein, whichCheck, inf_time, cell_volume, infWater_timestep, ts_check=1, plotting=F){
  switch(whichCheck,
         totalwater = {
                        modelwater = dplyr::summarize(filein, modelsum = sum(value, na.rm=T)) 
                        comparison = data.frame(water_model = as.integer(modelwater) * cell_volume,
                                                water_real = sum(seq(1,inf_time)) * infWater_timestep
                                               )
                      },
         waterpertimestep = {
                        modelwater = dplyr::group_by(filein, Timestep) %>%
                                     dplyr::summarize(modelsum = sum(value/Timestep, na.rm=T)) 
                        comparison = data.frame(timestep = modelwater$Timestep,
                                                water_model = modelwater$modelsum * cell_volume,
                                                water_real = infWater_timestep
                                               )
                        if(plotting){ print(ggplot(modelwater, aes(x=Timestep, y=modelsum)) + geom_line()) }
                      },
         tswater = {
                        # modelwater = dplyr::filter(filein, Timestep == ts_check) %>%
                        #              dplyr::summarize(modelsum = sum(value, na.rm=T)) 
                        # comparison = data.frame(water_model = as.integer(modelwater),
                        modelwater = dplyr::filter(filein, Timestep == ts_check)
                        comparison = data.frame(water_model = sum(modelwater$value, na.rm = T) * cell_volume,
                                                water_real = ts_check * infWater_timestep
                                               )
                      }
  )
  return(comparison)
}

#' @title plot irrigated cut profile at certain time step
#'
#' @description test
#'
#' @param test
#' @param test
#' @param test
#' ...
#' @details missing
#' @references Marvin Reich (2016), mreich@@gfz-potsdam.de
#' @examples missing

plotIrrigationProfile <- function(filein, tstep = 360, cutrel = 2, plotvar = "x", showlegend = T){
  library(viridis)
  # reduce dataset to desired time step
  switch(plotvar,
        x = {cutposition = min(filein$y) + cutrel
            data_plot = dplyr::filter(filein, Timestep == tstep & y == cutposition)},
        y = {cutposition = min(filein$x) + cutrel
            data_plot = dplyr::filter(filein, Timestep == tstep & x == cutposition)}
  )
  # maximal vertical extent
  maxy = max(data_plot$zgrid, na.rm=T)
  # legend !?
  if(showlegend){ leg = "right"
  }else{ leg = "none"}
  switch(plotvar,
        x = {
            data.gg = ggplot(data_plot, aes(x = x, y = zgrid)) + geom_raster(aes(fill = value)) + ylim(maxy,0) + 
            theme(legend.position=leg) +
            ylab("Depth [m]") + xlab("x [m]") + 
            scale_fill_gradientn(colours = rev(viridis(7)))
                   },
        y = {
            data.gg = ggplot(data_plot, aes(x = y, y = zgrid)) + geom_raster(aes(fill = value)) + ylim(maxy,0) + 
            theme(legend.position=leg) +
            ylab("Depth [m]") + xlab("y [m]") + 
            scale_fill_gradientn(colours = rev(viridis(7)))
                   }
  )
  return(data.gg) 
}

#' @title Hydro-gravimetric model
#'
#' @description 3D distribution algorithm, modeling the soil infiltration of water from a sprinkling experiment
#'
#' @param test
#' @param test
#' @param test
#' ...
#' @details missing
#' @references Marvin Reich (2016), mreich@@gfz-potsdam.de
#' @examples missing

inf_model = function(param_vec){

##########################################
## directories
##########################################
# # local
# dir_input = "/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/"
# dir_output = "/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/"
# dir_plots = "/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/plots/"
# cluster
dir_plots = paste0(dir_output,"plots/")

##########################################
## scenario properties
# should a water distribution be used?
# IntensityDistribution = "homo"
# IntensityDistribution = Intensity_distribution
# IntensityDistribution = "ideal"
##########################################

##########################################
## threshold for saturation: delta theta
# valid for all scenarios below (except ponding)
# macropores
# dtheta_macro = 0.025 # [m³/m³]
# dtheta_macro = 0.05 # [m³/m³]
# dtheta_macro = 0.1 # [m³/m³]
# dtheta_macro = 0.2 # [m³/m³]
# piping
# dtheta_pipe = 0.025 # [m³/m³]
# dtheta_pipe = 0.05 # [m³/m³]
# dtheta_pipe = 0.1 # [m³/m³]
# dtheta_pipe = 0.2 # [m³/m³]
##########################################

##########################################
## load infiltration data
##########################################

print("start calculatings for infiltration: COMBINED Extended scenarios..")

# ####################
# ## debugging
# dir_output = "/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/"
# load(file="/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/Intensity_distribution_real_IDW.rdata")
# load(file="/home/mreich/Dokumente/written/beregnungsPaper/data/output/gravity/grids/gridcells.rdata")
# load(file="/home/mreich/Dokumente/written/beregnungsPaper/data/output/gravity/grids/gcomp_irrigation_domain_allValid_3m.rdata")
# exp3_meta = read.table(file="/home/mreich/Dokumente/written/beregnungsPaper/data/input/Irrigation/Irrigation_precondition_dry", skip= 5, nrows=8, dec=".", colClasses = character(), stringsAsFactors=F)
# zlayers = round(seq(0,3, by=.1),1)
# precip_time = 360
# ####################

# irrigation grid template
# this includes predefined:
# coordinates (x,y,z)
# time information (timesteps, real timestamps)
## maybe not necessary anymore !?
# load(file=paste0(dir_input,"irrigation_initial_3mdepth.rdata"))

# ##########
# ## logging to file
# logfile = paste0("irrigation zgrid: ",unique(Irrigation_in$zgrid))
# write.table(logfile, file=paste0(dir_output, "logfile"), append=T)
# ##########

# duration of irrigation
# precip_time = max(Irrigation_in$Timestep) # [min]
# precip_time = 360 # [min]
# infiltrating water volume per minute
# water_vol_min [m³ / min]
# load(file=paste0(dir_input, "irrigationvolume_min_simpleScenarios.rdata"))
# # water vol from experiment 3
# exp3_meta = read.table(file="./input/Irrigation_precondition_dry", skip= 5, nrows=8, dec=".", colClasses = character(), stringsAsFactors=F)
# water_total_experiment = as.numeric(exp3_meta[6,2]) + as.numeric(exp3_meta[7,2]) # [m³]
# water_vol_min = water_total_experiment / precip_time #[m³/min]


###################
## load model configuration
load(file="configfile.rdata")
dir_input = configfile$dir_input
dir_output = configfile$dir_output
precip_time = configfile$precip_time
IntensityDistribution = configfile$IntensityDistribution
water_vol_min = configfile$water_vol_min
gcompfile = configfile$gcompfile
gravityObs = configfile$gravityObs

# volume of grid cell 
vol_cell = 0.1 * 0.1 * 0.1 # [m³]
# gridcells
load(file=paste0(dir_input, "gridcells.rdata"))
# number of cells per layer
# num_cell = length(gridcells$x)

# vertical layers
# zlayers = round(unique(Irrigation_in$zgrid),1)

## load gravity calculation data
# load gravity effect grid
load(file=paste0(dir_input, gcompfile))
# load igrav time series in same period
load(file=paste0(dir_input, gravityObs))
# set same column name for joining datasets
colnames(igrav_exp3)[2] = "gmod"
igrav_exp3_cor = mutate(igrav_exp3, gmod = gmod - min(gmod))
igrav_timesteps = data.frame(Timestep = 1:length(igrav_exp3_cor$gmod[-1]), gmod = igrav_exp3_cor$gmod[-1])

Irrigation_grid = dplyr::select(gcomp_irrigation_domain, x,y,z,zgrid)

# vertical layers
zlayers = round(unique(Irrigation_grid$zgrid),1)
# number of cells per layer
num_cell = length(unique(Irrigation_grid$x)) *  length(unique(Irrigation_grid$y))

# ##########
# ## logging to file
# logfile = paste0("irrigation zgrid: ",unique(Irrigation_in$zgrid))
# write.table(logfile, file=paste0(dir_output, "logfile"), append=T)
# ##########

##########################################
## set scenario settings: intensity distribution
switch(IntensityDistribution,
       ideal = {
          load(file=paste0(dir_input, "Intensity_distribution_ideal_IDW.rdata"))
          # Irrigation_in = inner_join(Irrigation_in, Intensity_distribution)
       },
       real = {
          load(file=paste0(dir_input, "Intensity_distribution_real_IDW.rdata"))
          # Irrigation_in = inner_join(Irrigation_in, Intensity_distribution)
       }
)
##########################################

####################
## prepare statistis outout
stats = data.frame()
####################

print("Finished loading setup parameters.")

##########################################
## load parameterset
##########################################
# load(file=paste0(dir_input,"parametersets_ModulebasedScenarios.rdata"))
# load(file=paste0(dir_input,"parametersets_ModulebasedScenarios_selected.rdata"))
# load(file=paste0(dir_input,"parametersets_ModulebasedScenarios_selected2.rdata"))
# ## start for loop
# ## criteria: fit gmod to gobs
# for(n_param in 1:length(parametersets[,1])){
# # for(n_param in 1:1){
# print(paste0("Modelrun started: ", n_param))
# # pass parameters
dtheta_macro = param_vec[1]
dtheta_pipe = param_vec[2]
# parameter values in meters have to be rounded
# otherwise values will NOT match grid discretization !!
mdepth = round(param_vec[3],1)
pipedepth = round(param_vec[4],1)
##########################################
##########################################

# dtheta_macro = 0.1 # [m³/m³]
# dtheta_pipe = 0.04 # [m³/m³]

# depth of macropore layer thickness
# mdepth = .3 # [m]
# determine vertical start
mdepth_layer = which(zlayers == mdepth)
# print(mdepth_layer)
# print(zlayers)
# print(dtheta_macro)
# print(dtheta_pipe)

# # depth of pipe routing
# # pipedepth = mdepth + 0.1 # [m]
# pipedepth = 0.8  # [m]
# determine vertical start
pipe_layer = which(zlayers == pipedepth)
# ####################
# 
# ## create standard data.frame, valid for each time step
# # tsx = data.frame(x = rep(gridcells$x, length(zlayers)),
# #                  y = rep(gridcells$y, length(zlayers)),
# #                  column = rep(gridcells$ncell, length(zlayers)),
# #                  zgrid = rep(zlayers, each = length(gridcells$x)),
# #                  cnt = 1,
# #                  # layerfill = 1, # has to be included as LAST column !!
# #                  Timestep = 0,
# #                  value = 0,
# #                  prevalue = 0
# #                  )

tsx = dplyr::mutate(Irrigation_grid,
      column = rep(gridcells$ncell, length(zlayers))) %>%
      dplyr::mutate(cnt = 1) %>%
      dplyr::mutate(Timestep = 0) %>%
      dplyr::mutate(value = 0) %>%
      dplyr::mutate(prevalue = 0)

## tag vertical layers with infiltration process
layer_params = data.frame(zgrid = zlayers,
                         infProcess = c(rep("macro", mdepth_layer), rep("pipe",(length(zlayers) - mdepth_layer))),
                         # nlayer = c(rep(1,mdepth_layer),seq(2,length.out=(length(zlayers) - mdepth_layer))),
                         nlayer = c(rep(1,mdepth_layer),rep(1000,(pipe_layer - mdepth_layer)), seq(1,length.out=(length(zlayers) - pipe_layer))),
                         dtheta = c(rep(dtheta_macro,mdepth_layer),rep(dtheta_pipe,(length(zlayers) - mdepth_layer)))
              )

## tag cells with layer parameters
tsx = inner_join(tsx, layer_params) # %>%
      # inner_join(Irrigation_grid)

## calculate number of "same" cells per layers in a column
cellnums = group_by(tsx, column, nlayer) %>%
# cellnums = group_by(tsx, column, nlayer, infProcess) %>%
           dplyr::summarize(cellsLayerColumn = sum(cnt, na.rm=T)) %>%
           ungroup()

## join with intensity distribution coefficents
tsx = inner_join(tsx, Intensity_distribution) %>%
      mutate(distrWater = water_vol_min * intensity / num_cell / vol_cell) %>%
      mutate(layerfill = 1) %>%
      inner_join(cellnums)

## because this one is the "filling-index", and gets exchanged, it has to be included last
# starting everywhere with layer one (= macropore flow layers)
# tsx$layerfill = 1

####################
## start with for loop and TS1
# time.s = proc.time()
for(i in 1:precip_time){ 
## pass previous values to new time step data.frame
tsx$prevalue = tsx$value
# tsx$value = 0
tsx$Timestep = i

## fill cells with water of time step x
# tsx = dplyr::mutate(tsx, value = ifelse(nlayer == layerfill, prevalue + (distrWater / cellsLayerColumn), prevalue))
tsx = dplyr::mutate(tsx, value_macro = ifelse(infProcess == "macro" & nlayer == layerfill, prevalue + (distrWater / cellsLayerColumn), prevalue)) %>%
      dplyr::mutate(value_macro = ifelse(infProcess == "macro", value_macro, 0)) %>%
      dplyr::mutate(value_pipe = ifelse(infProcess == "pipe" & nlayer == layerfill, prevalue + (distrWater / cellsLayerColumn), prevalue)) %>%
      dplyr::mutate(value_pipe = ifelse(infProcess == "pipe", value_pipe, 0)) %>%
      dplyr::mutate(value = value_macro + value_pipe)

## combine with data from previous time steps
# Irrigation_macropiping = rbind(Irrigation_macropiping, tsx)
# save(tsx, file=paste0(dir_output, "tsx_paramset_", n_param, "_TS", i, ".rdata"))
# save(tsx, file=paste0(dir_output, "/scenarios/combiExt/tsx_paramset_", n_param, "_TS", i, ".rdata"))
if(i == 1){
write.table(tsx, file=paste0(dir_output, "raw/tsx_TS", formatC(i, width=3, flag="0"), ".txt"), sep="\t", row.names=F, col.names=T, append=F)
}else{
write.table(tsx, file=paste0(dir_output, "raw/tsx_TS", formatC(i, width=3, flag="0"), ".txt"), sep="\t", row.names=F, col.names=F, append=F)
}
## store header names for later usage
## write header to "first file to concatate"
# tsx_header = data.frame(c(list(),colnames(tsx)))
# write.table(tsx_header, file=paste0(dir_output, "raw/tsx_TS0.txt"), sep="\t", row.names=F, col.names=F, append=F)

## testing
# tsx = data.frame(column=c(1,2,1,2), infProcess = c(rep("macro",2),rep("pipe",2)),
#                  dtheta=c(0.1,0.1,0.2,0.2), nlayer= c(1,1,2,2),
#                  value=c(0.15,0.09,0.15,0.15))

## check for saturated cells
layerfilling = dplyr::mutate(tsx, saturated = ifelse(value >= dtheta, 1000, nlayer)) %>%
               group_by(column, infProcess) %>%
               dplyr::summarize(layerfill = min(saturated, na.rm=T))

# layerfilling = dplyr::mutate(tsx, saturated = ifelse(value >= dtheta, T, F)) %>%
#                group_by(column, infProcess) %>%
#                dplyr::filter(saturated == F) %>%
#                dplyr::summarize(layerfill = min(nlayer, na.rm=T))

## change information of which layer in each column should be filled at next time step
tsx = dplyr::select(tsx, - layerfill) %>%
      inner_join(layerfilling)

cellnums_dynamic = dplyr::mutate(layerfilling, ncells = ifelse(infProcess == "macro" & layerfill < 2, mdepth * 10 +1, 0)) %>%
                   dplyr::mutate(ncells = ifelse(infProcess == "pipe", 1, ncells)) %>%
                   dplyr::group_by(column) %>%
                   dplyr::summarize(cellsLayerColumn = sum(ncells, na.rm=T))

## change information how many cells will be filled next timestep
tsx = dplyr::select(tsx, - cellsLayerColumn) %>%
      inner_join(cellnums_dynamic)

} # end for loop
# time.e = proc.time()
# print("model ascii files")
# print(time.e - time.s)

# # ####################
# # ## debugging
# # i = 360
# # load(file=paste0(dir_output, "/scenarios/combiExt/tsx_TS", i, ".rdata"))
# # sum(tsx$value) * vol_cell
# # watbal = data.frame(Timestep = 1:360, val=0)
# # for(i in 1:360){
# # for(i in 1:precip_time){
# # load(file=paste0(dir_output, "/scenarios/combiExt/tsx_TS", i, ".rdata"))
# # # water irrigated this timestep
# # val = sum(tsx$value) / i * vol_cell
# # watbal$Timestep[i] = i
# # watbal$val[i] = val
# # }
# # watbal$cumval = cumsum(watbal$val)
# # # plot vertical water distribution
# # cutrel = 8
# # cutposition = min(tsx$y) + cutrel
# # data_plot = dplyr::filter(tsx, y == cutposition)
# # maxy = max(data_plot$zgrid, na.rm=T)
# # ggplot(data_plot, aes(x = x, y = zgrid)) + geom_raster(aes(fill = value)) + ylim(maxy,0) + 
# # theme(legend.position="right") +
# # ylab("Depth [m]") + xlab("x [m]") + 
# # scale_fill_gradientn(colours = rev(viridis(7)))
# # ####################
# #               
# # print("finished modeling")
# print("starting data loading and stichting")
# # ####################
# # ## load and stich all datasets
# # ## define empty result data.frame
# # Irrigation_macropiping = data.frame()
# # 
# # for(i in 1:precip_time){
# # load(file=paste0(dir_output, "tsx_paramset_", n_param, "_TS", i, ".rdata"))
# # Irrigation_macropiping = rbind(Irrigation_macropiping, tsx)
# # }
# # print("finished data loading and stichting")
# # ## remove indexing, not needed columns (to save space)
# # # Irrigation_macropiping = dplyr::select(Irrigation_macropiping, - cnt, - layerfill)
# 
####################
## stich ascii files using bash
# time.s = proc.time()
print("stiching output files")
systemcall_stich = paste0("cat ", dir_output, "raw/*.txt > ", dir_output, "raw/rawdata")
#system("cat /home/hydro/mreich/Irrigation/output/modbased/raw/*.txt > /home/hydro/mreich/Irrigation/output/modbased/raw/rawdata")
system(systemcall_stich)
# time.e = proc.time()
# print(time.e - time.s)
####################
## load stitched file
# time.s = proc.time()
print("read stiched output files")
# regular read.table
# Irrigation_macropiping = read.table(file=paste0(dir_output, "raw/rawdata.txt"), header = F, sep="\t", dec=".")
# colnames(Irrigation_macropiping) = tsx_header
# data.tables fread
Irrigation_macropiping = fread(file=paste0(dir_output, "raw/rawdata"), header = T, sep="\t", dec=".", 
                               select = c("x","y","z","zgrid","value","Timestep"))
## convert data.table to data.frame
setDF(Irrigation_macropiping)
# time.e = proc.time()
# print(time.e - time.s)

####################
## check if all water was actually distributed
# water_bal = group_by(Irrigation_macropiping, Timestep) %>%
#                 dplyr::summarize(water_distributed = sum(value / Timestep, na.rm = T) * vol_cell)
# save(water_bal, file=paste0(dir_output,"water_bal_", n_param, ".rdata"))

####################
## reasonability checks ("sub"-unit testing on scenario basis)
# check total water of system
print("water balance MACROPORES & PIPING:")
# print( checkWaterVolumes(Irrigation_macropiping, "totalwater", precip_time, vol_cell, water_vol_min) )
# # check water of each timestep
# # check water of one timestep
checkTS = precip_time
# checkTS = 50
# print("water balance PISTON FLOW (ts = 360):")
checkWaterVolumes(Irrigation_macropiping, "tswater", precip_time, vol_cell, water_vol_min, checkTS)
plots=F
print(checkWaterVolumes(Irrigation_macropiping, "waterpertimestep", precip_time, vol_cell, water_vol_min, plotting=plots))
# plot
png(file=paste0(dir_plots, "Distribution_simple_macropiping_mean_", n_param, ".png"), width=1000, height=1000, res=250)
print(plotInfWater(Irrigation_macropiping, "means"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_max_", n_param, ".png"), width=1000, height=1000, res=250)
print(plotInfWater(Irrigation_macropiping, "theta"))
dev.off()

##########
# load(file=paste0(dir_output, "Irrigation_combiExt_macropiping_", n_param, ".rdata"))
# plot profile (along x)
# igrav_x = 4564082.00
# igrav_y = 5445669.70
yrel = 8 # [m]
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs60_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 60, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs120_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 120, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs180_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 180, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs240_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 240, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs300_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 300, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs360_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 360, yrel, "x"))
dev.off()

print(paste0("Saving Irrigation data for n_param: ", n_param))
## save data
save(Irrigation_macropiping, file=paste0(dir_output, "Irrigation_combiExt_macropiping_", n_param, ".rdata"))

# 
##debug
#load data
# load(file=paste0(dir_output, "Irrigation_combiExt_macropiping_", n_param, ".rdata"))
# print(str(Irrigation_macropiping))
# print(str(gcomp_irrigation_domain))
# tt =dplyr::select(Irrigation_macropiping, x,y,z,value,Timestep)
# print(str(tt))
# print(range(tt$Timestep))
# ttt = left_join(gcomp_irrigation_domain, tt)
# print(str(ttt))
# print(range(ttt$Timestep))
# print(range(ttt$value))
# print("other test irrigation dataset:")
# load(file="/home/hydro/mreich/Irrigation/output/combi/Irrigation_simple_macropiping.rdata")
# print("-zgrid")
# tt =dplyr::select(Irrigation_macropiping, -zgrid)
# print(str(tt))
# ttt = left_join(gcomp_irrigation_domain, tt)
# print(str(ttt))
# print("select positiv")
# tt =dplyr::select(Irrigation_macropiping, x,y,z,value,Timestep)
# print(str(tt))
# ttt = left_join(gcomp_irrigation_domain, tt)
# print(str(ttt))


########################################
## gravity response in nm/s²
########################################
## !!
## due to saving into ascii, reading and stiching (within the processing procedure)
## joining columns (x,y,z) have to be rounded! in order to match with gravity component grid
## !!
Irrigation_macropiping$x = round(Irrigation_macropiping$x,2)
Irrigation_macropiping$y = round(Irrigation_macropiping$y,2)
Irrigation_macropiping$z = round(Irrigation_macropiping$z,2)
gcomp_irrigation_domain$x = round(gcomp_irrigation_domain$x,2)
gcomp_irrigation_domain$y = round(gcomp_irrigation_domain$y,2)
gcomp_irrigation_domain$z = round(gcomp_irrigation_domain$z,2)

# should timesteps or POSIXct units be shown on x-axis?
showRealdates = F
# gsignal_irrigation_macropiping = gsignal_grids_3d(gcomp_irrigation_domain, dplyr::select(Irrigation_macropiping, -zgrid), showRealdates)
print("calculating gravity response..")
gsignal_irrigation_macropiping = gsignal_grids_3d(gcomp_irrigation_domain, dplyr::select(Irrigation_macropiping, x,y,z,value,Timestep), showRealdates)
#save gsignal
save(gsignal_irrigation_macropiping, file=paste0(dir_output, "gmod_Irrigation_macropiping_", n_param, ".rdata"))
# print(str(gsignal_irrigation_macropiping))

## combine datasets and plot
gmod = rbind(
         cbind(igrav_timesteps, Scenario="iGrav (observed)"),
	     cbind(gsignal_irrigation_macropiping, Scenario="Macro & Piping")
         )

png(file=paste0(dir_plots, "gmod_signal_Irrigation_combinedExtScenarios_macropipe_", n_param, ".png"), width=1500, height=1000, res=250)
plot(ggplot(gmod, aes(x=Timestep, y=gmod, colour=Scenario)) + geom_line() + 
	ylab("Gravity [nm/s²]") + xlab("Time since irrigation start [min]"))
dev.off()

####################
## calculate fit to gobs
# ks = ks.test(gsignal_irrigation_macropiping$gmod, igrav_timesteps$gmod)
# gfit = gof(gsignal_irrigation_macropiping$gmod, igrav_timesteps$gmod)
# ## construct fitting data.frame
# gfit_stats = data.frame(c(list(),gfit))
# colnames(gfit_stats) =  row.names(gfit)
# gfit_stats$KS_D = ks$statistic
# gfit_stats$KS_p = ks$p.value

## regular KGE
kge_value = KGE(gsignal_irrigation_macropiping$gmod, igrav_timesteps$gmod)
## changing scaling factor of component BIAS
# kge_value = KGE(gsignal_irrigation_macropiping$gmod, igrav_timesteps$gmod, s=c(2.5/6,2.5/6,1/6))
kge_fit = 1 - kge_value
########################################
## write model run parameters and statistics
########################################
# print("Statistical measures and indicators, water mass balance, etc..")
# checkTS = precip_time
# model_stats = checkWaterVolumes(Irrigation_macropiping, "tswater", precip_time, vol_cell, water_vol_min, checkTS)
# model_stats$waterbalance = round(model_stats$water_model / model_stats$water_real, 3)
# model_stats$dtheta_macro = dtheta_macro
# model_stats$dtheta_pipe = dtheta_pipe
# model_stats$mdepth = mdepth
# model_stats$pipedepth = pipedepth
# model_stats$parameterset = n_param
# ## combine with overall statistic variable
# stats = rbind(stats, cbind(model_stats, gfit_stats)) #, make.row.names=F)
# ## save statistics
# save(stats, file=paste0(dir_output, "modelrun_stats.rdata"))
# # appending to existing ascii-file
# write.table(stats, file=paste0(dir_output, "modelrun_stats.csv"), sep="\t", dec=".", row.names = F, col.names = T, append = T)

####################
## clean up memory
rm(Irrigation_macropiping, gsignal_irrigation_macropiping)
gc()
## move to next n_param value for plot indexing
n_param <<- n_param + 1

## returning quality criteria:
## KGE
return(kge_fit) 

print("finished MACROPORES & PIPING !")
####################
} # end of function


#' @title Interpolate 3D nodes of a time series to regular grid
#'
#' @description interpolate a time series, which has 3 dimensions, using IDW and time-stacking
#' 
#' @param data_input data to be interpolated. this has to be a data.frame with columns (x, y, z, value).
#' @param grid_discr vector of discretization of new grid in (x,y,z).
#' @param grid_depth vector of vertical extents of new grid in c(min,max).
#' @param grid_cords grid to be interpolated to. if no grid is passed, it is created from input_data spatial ranges.
#' @param nintmax maximal number of points to consider in the surroundings for one interpolation point
#' @details missing
#' @references Marvin Reich (2017), mreich@@gfz-potsdam.de
#' @examples missing

nodestogrid_3d = function(data_input, grid_discr, depth_split, grid_cords = NA, nintpmax = 10){
library(gstat)

# if no grid is passed as input
if(is.na(grid_cords)){
# generate grid out of input data
#generate regular-spaced grid
x_res = decimalplaces(grid_discr[1])
y_res = decimalplaces(grid_discr[2])
# z_res = decimalplaces(grid_discr[3])
grid.x <- seq(round(min(data_input$x), x_res), round(max(data_input$x), x_res), by=grid_discr[1])
grid.y <- seq(round(min(data_input$y), y_res), round(max(data_input$y), y_res), by=grid_discr[2])
grid.z <- seq(min(depth_split), max(depth_split), by=grid_discr[3])
grid.xyz <- expand.grid(x=grid.x, y=grid.y, z=grid.z)
}

#interpolate and "stack" for each timestep
result_grid=data.frame()
for(i in unique(data_input$datetime)){
data_in = dplyr::filter(data_input, datetime == i & is.na(value) == F) #filter for one timestep
#interpolate data to new grid
idw.gstat = gstat(formula = value ~ 1, locations = ~ x + y + z, data = data_in, nmax = nintpmax, set = list(idp = 2))
data_convert = predict(idw.gstat, grid.xyz)
data_interpolated = cbind(datetime = i, data_convert[,-5])
colnames(data_interpolated)[5] = "value"
result_grid = rbind(result_grid, data_interpolated)
}
#return(grid_interpolated)
return(result_grid)
} #end function


#' @title Interpolate 3D nodes of a time series to regular grid using parralel computing
#'
#' @description interpolate a time series, which has 3 dimensions, using IDW and time-stacking
#' 
#' @param data_input data to be interpolated. this has to be a data.frame with columns (x, y, z, value).
#' @param grid_discr vector of discretization of new grid in (x,y,z).
#' @param grid_depth vector of vertical extents of new grid in c(min,max).
#' @param grid_cords grid to be interpolated to. if no grid is passed, it is created from input_data spatial ranges.
#' @param nintmax maximal number of points to consider in the surroundings for one interpolation point
#' @details missing
#' @references Marvin Reich (2017), mreich@@gfz-potsdam.de
#' @examples missing

nodestogrid_3d_PP = function(data_input, grid_discr, depth_split, grid_cords = NA, nintpmax = 10){
library(gstat)
library(foreach)
library(doParallel, quiet=T)

# if no grid is passed as input
if(is.na(grid_cords)){
# generate grid out of input data
# generate regular-spaced grid
x_res = decimalplaces(grid_discr[1])
y_res = decimalplaces(grid_discr[2])
# z_res = decimalplaces(grid_discr[3])
grid.x <- seq(round(min(data_input$x), x_res), round(max(data_input$x), x_res), by=grid_discr[1])
grid.y <- seq(round(min(data_input$y), y_res), round(max(data_input$y), y_res), by=grid_discr[2])
grid.z <- seq(min(depth_split), max(depth_split), by=grid_discr[3])
grid.xyz <- expand.grid(x=grid.x, y=grid.y, z=grid.z)
}

# settings for parallel computing
cores = detectCores() #detect cores
cluster = makeCluster(cores) #create cluster
registerDoParallel(cluster) #register cluster

# interpolate and "stack" for each timestep
result_grid = foreach(i=unique(data_input$datetime),.combine=rbind,.packages=c('dplyr','gstat')) %dopar% {
data_in = dplyr::filter(data_input, datetime == i & is.na(value) == F) #filter for one timestep
#interpolate data to new grid
idw.gstat = gstat(formula = value ~ 1, locations = ~ x + y + z, data = data_in, nmax = nintpmax, set = list(idp = 2))
data_convert = predict(idw.gstat, grid.xyz)
data_interpolated = cbind(datetime = i, data_convert[,-5])
}

# renaming value column
colnames(result_grid)[5] = "value"

# stop clusters
stopCluster(cluster)

# return results
return(result_grid)
} #end function


#' @title Interpolate 2D / 3D nodes of a time series to regular grid using parralel computing
#'
#' @description interpolate a time series, which has 3 dimensions, using IDW and time-stacking
#' 
#' @param data_input data to be interpolated. this has to be a data.frame with columns (x, y, z, value).
#' @param grid_discr vector of discretization of new grid in (x,y,z).
#' @param grid_depth vector of vertical extents of new grid in c(min,max).
#' @param grid_cords grid to be interpolated to. if no grid is passed, it is created from input_data spatial ranges.
#' @param nintmax maximal number of points to consider in the surroundings for one interpolation point
#' @details missing
#' @references Marvin Reich (2017), mreich@@gfz-potsdam.de
#' @examples missing

nodestogrid_PP = function(data_input, grid_discr, depth_split, grid_new = NA, nintpmax = 10, dimension = "d2"){
library(gstat)
library(foreach)
library(doParallel, quiet=T)

switch(dimension,
       d2 = {
            # if no grid is passed as input
            if(is.na(grid_new)){
            # generate grid out of input data
            # generate regular-spaced grid
            x_res = decimalplaces(grid_discr[1])
            # z_res = decimalplaces(grid_discr[3])
            grid.x <- seq(round(min(data_input$x), x_res), round(max(data_input$x), x_res), by=grid_discr[1])
            grid.z <- seq(min(depth_split), max(depth_split), by=grid_discr[3])
            grid_new <- expand.grid(x=grid.x, z=grid.z)
            }
            
            # settings for parallel computing
            cores = detectCores() #detect cores
            cluster = makeCluster(cores) #create cluster
            registerDoParallel(cluster) #register cluster
            
            # interpolate and "stack" for each timestep
            result_grid = foreach(i=unique(data_input$datetime),.combine=rbind,.packages=c('dplyr','gstat')) %dopar% {
            data_in = dplyr::filter(data_input, datetime == i & is.na(value) == F) #filter for one timestep
            #interpolate data to new grid
            idw.gstat = gstat(formula = value ~ 1, locations = ~ x + z, data = data_in, nmax = nintpmax, set = list(idp = 2))
            data_convert = predict(idw.gstat, grid_new)
            data_interpolated = cbind(datetime = i, data_convert[,-4])
            }
            
            # renaming value column
            colnames(result_grid)[4] = "value"
            
            # stop clusters
            stopCluster(cluster)
       },
       d3 = {
            # if no grid is passed as input
            if(is.na(grid_new)){
            # generate grid out of input data
            # generate regular-spaced grid
            x_res = decimalplaces(grid_discr[1])
            y_res = decimalplaces(grid_discr[2])
            # z_res = decimalplaces(grid_discr[3])
            grid.x <- seq(round(min(data_input$x), x_res), round(max(data_input$x), x_res), by=grid_discr[1])
            grid.y <- seq(round(min(data_input$y), y_res), round(max(data_input$y), y_res), by=grid_discr[2])
            grid.z <- seq(min(depth_split), max(depth_split), by=grid_discr[3])
            grid_new <- expand.grid(x=grid.x, y=grid.y, z=grid.z)
            }
            
            # settings for parallel computing
            cores = detectCores() #detect cores
            cluster = makeCluster(cores) #create cluster
            registerDoParallel(cluster) #register cluster
            
            # interpolate and "stack" for each timestep
            result_grid = foreach(i=unique(data_input$datetime),.combine=rbind,.packages=c('dplyr','gstat')) %dopar% {
            data_in = dplyr::filter(data_input, datetime == i & is.na(value) == F) #filter for one timestep
            #interpolate data to new grid
            idw.gstat = gstat(formula = value ~ 1, locations = ~ x + y + z, data = data_in, nmax = nintpmax, set = list(idp = 2))
            data_convert = predict(idw.gstat, grid_new)
            data_interpolated = cbind(datetime = i, data_convert[,-5])
            }
            
            # renaming value column
            colnames(result_grid)[5] = "value"
            
            # stop clusters
            stopCluster(cluster)
       }
)

# return results
return(result_grid)
} #end function


#' @title Hydro-gravimetric model (incl. lateral flow)
#'
#' @description 3D distribution algorithm, modeling the soil infiltration of water from a sprinkling experiment
#'
#' @param paramvec Numeric vector, proving input in this EXACT ORDER of the parameter values: saturation deficit of 1st process (macro pores), saturation deficit of 2nd process, total vertical thickness (extent) of 1st process (macropores), scaling factor (0 to 1) defining the relatinship between lateral and vertical flow after saturation of a cell.
#' @param test
#' @param test
#' ...
#' @details The function was written to be easily usable together with optimization tools.
#' It thus  needs a configfile.rdata-file with the following columns, each consisting of one single value:
#' dir_input, dir_output, precip_time, IntensityDistributionution, water_vol_min, gcompfile, gravityObs, mb_permitted_error.

#' @references Marvin Reich (2016), mreich@@gfz-potsdam.de
#' @examples missing

inf_model_3d = function(param_vec){

##########################################
## directories
##########################################
# # local
# dir_input = "/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/"
# dir_output = "/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/"
# dir_plots = "/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/plots/"
# cluster
# dir_plots = paste0(dir_output,"plots/")

##########################################
## scenario properties
# should a water distribution be used?
# IntensityDistribution = "homo"
# IntensityDistribution = Intensity_distribution
# IntensityDistribution = "ideal"
##########################################

##########################################
## load infiltration data
##########################################

print("start calculatings for infiltration: COMBINED Extended scenarios..")

# ####################
# ## debugging
# library(dplyr)
# library(reshape2)
# library(raster)
# library(tidyr)
# dir_output = "/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/"
# load(file="/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/Intensity_distribution_real_IDW.rdata")
# load(file="/home/mreich/Dokumente/written/beregnungsPaper/data/output/gravity/grids/gridcells.rdata")
# load(file="/home/mreich/Dokumente/written/beregnungsPaper/data/output/gravity/grids/gcomp_irrigation_domain_allValid_3m.rdata")
# precip_time = 360
# exp3_meta = read.table(file="/home/mreich/Dokumente/written/beregnungsPaper/data/input/Irrigation/Irrigation_precondition_dry", skip= 5, nrows=8, dec=".", colClasses = character(), stringsAsFactors=F)
# water_total_experiment = as.numeric(exp3_meta[6,2]) + as.numeric(exp3_meta[7,2]) # [m³]
# water_vol_min = water_total_experiment / precip_time #[m³/min]
# zlayers = round(seq(0,3, by=.1),1)
# # params
# dtheta_macro = 0.2
# dtheta_pipe = 0.01
# mdepth = 0.5
# pipedepth = 0.6
# latflow_fac = 0.5
# mb_permitted_error = 0.05
# vertflow_fac = 1 - latflow_fac
# vol_cell = 0.1 * 0.1 * 0.1 # [m³]
# Irrigation_grid = dplyr::select(gcomp_irrigation_domain, x,y,z,zgrid)
# num_cell = length(unique(Irrigation_grid$x)) *  length(unique(Irrigation_grid$y))
# cfactor = 0.25
# sfactor = 1 - cfactor
# dir_output = "/home/mreich/temp/"
# ####################

# ##########
# ## logging to file
# logfile = paste0("irrigation zgrid: ",unique(Irrigation_in$zgrid))
# write.table(logfile, file=paste0(dir_output, "logfile"), append=T)
# ##########

###################
## load model configuration
load(file="configfile.rdata")
dir_input = configfile$dir_input
dir_output = configfile$dir_output
precip_time = configfile$precip_time
IntensityDistribution = configfile$IntensityDistribution
water_vol_min = configfile$water_vol_min
gcompfile = configfile$gcompfile
gravityObs = configfile$gravityObs
mb_permitted_error = configfile$mb_permitted_error

# setting plot directory
dir_plots = paste0(dir_output,"plots/")

# volume of grid cell 
vol_cell = 0.1 * 0.1 * 0.1 # [m³]
# gridcells
load(file=paste0(dir_input, "gridcells.rdata"))

## load gravity calculation data
# load gravity effect grid
load(file=paste0(dir_input, gcompfile))
# load igrav time series in same period
load(file=paste0(dir_input, gravityObs))
# set same column name for joining datasets
colnames(igrav_exp3)[2] = "gmod"
igrav_exp3_cor = mutate(igrav_exp3, gmod = gmod - min(gmod))
igrav_timesteps = data.frame(Timestep = 1:length(igrav_exp3_cor$gmod[-1]), gmod = igrav_exp3_cor$gmod[-1])

Irrigation_grid = dplyr::select(gcomp_irrigation_domain, x,y,z,zgrid)

# vertical layers
zlayers = round(unique(Irrigation_grid$zgrid),1)
# number of cells per layer
num_cell = length(unique(Irrigation_grid$x)) *  length(unique(Irrigation_grid$y))

# define factors for scaling between "side" and "corner" cell neighbours
# following (Quinn 1997), where cardinal (side) and diagnol (corner) factors are summed
# all 8 cells are delivered thus leading to the following factors
# for side cells
# 4 * 0.5/SUM(all factors for all cells) = 4 * 0.15
sfactor = 0.6
# for corner cells
# 4 * 0.35/SUM(all factors for all cells) = 4 * 0.1
cfactor = 0.4

# ##########
# ## logging to file
# logfile = paste0("irrigation zgrid: ",unique(Irrigation_in$zgrid))
# write.table(logfile, file=paste0(dir_output, "logfile"), append=T)
# ##########

##########################################
## set scenario settings: intensity distribution
switch(IntensityDistribution,
       ideal = {
          load(file=paste0(dir_input, "Intensity_distribution_ideal_IDW.rdata"))
          # Irrigation_in = inner_join(Irrigation_in, Intensity_distribution)
       },
       real = {
          load(file=paste0(dir_input, "Intensity_distribution_real_IDW.rdata"))
          # Irrigation_in = inner_join(Irrigation_in, Intensity_distribution)
       }
)
##########################################

####################
## prepare statistis outout
stats = data.frame()
####################

print("Finished loading setup parameters.")

##########################################
## pass parameters from DDS-function param_vec space
##########################################
dtheta_macro = param_vec[1]
dtheta_pipe = param_vec[2]
# parameter values in meters have to be rounded
# otherwise values will NOT match grid discretization !!
mdepth = round(param_vec[3],1)
# somewhere define that pipedepth > mdepth !!
# now pipedepth is directly below the macro pore layer
# pipedepth = round(mdepth + 0.1, 1)
# pipedepth is set individually
# this allows a space between macro pore layer and 2nd process
pipedepth = round(param_vec[4],1)
# lateral flow factor (seperate into lateral and vertical flow)
latflow_fac = param_vec[5]
vertflow_fac = 1 - latflow_fac

####################
## check validity of chosen thicknesses / depth of both infiltration processes
if(pipedepth <= mdepth){
  kge_fit = 1
  return(kge_fit) 
# if everything is okay, run normally
}else{ 

##########################################
## build up model domain space

# depth of macropore layer thickness
# mdepth = .3 # [m]
# determine vertical start
mdepth_layer = which(zlayers == mdepth)
# print(mdepth_layer)
# print(zlayers)
# print(dtheta_macro)
# print(dtheta_pipe)

# # depth of pipe routing
# # pipedepth = mdepth + 0.1 # [m]
# pipedepth = 0.8  # [m]
# determine vertical start
pipe_layer = which(zlayers == pipedepth)
## how many layers are between macro and pipe process?
layer_between = pipe_layer - mdepth_layer - 1
# ####################
# 
tsx = dplyr::mutate(Irrigation_grid,
      column = rep(gridcells$ncell, length(zlayers))) %>%
      dplyr::mutate(cnt = 1) %>%
      dplyr::mutate(Timestep = 0) %>%
      dplyr::mutate(value = 0) %>%
      dplyr::mutate(prevalue = 0)

## tag vertical layers with infiltration process
layer_params = data.frame(zgrid = zlayers,
                         infProcess = c(rep("macro", mdepth_layer), rep("pipe",(length(zlayers) - mdepth_layer))),
                         nlayer = c(rep(1,mdepth_layer), rep(1000, layer_between), seq(1,length.out=(length(zlayers) - (mdepth_layer + layer_between)))),
                         # nlayer = c(rep(1,mdepth_layer), seq(1,length.out=(length(zlayers) - mdepth_layer))),
                         dtheta = c(rep(dtheta_macro,mdepth_layer),rep(dtheta_pipe,(length(zlayers) - mdepth_layer)))
              )

## tag cells with layer parameters
tsx = inner_join(tsx, layer_params) # %>%
      # inner_join(Irrigation_grid)

## calculate number of "same" cells per layers in a column
cellnums = group_by(tsx, column, nlayer) %>%
# cellnums = group_by(tsx, column, nlayer, infProcess) %>%
           dplyr::summarize(cellsLayerColumn = sum(cnt, na.rm=T)) %>%
           ungroup()

## join with intensity distribution coefficents
tsx = inner_join(tsx, Intensity_distribution) %>%
      mutate(distrWater = water_vol_min * intensity / num_cell / vol_cell) %>%
      mutate(layerfill = 1) %>%
      inner_join(cellnums) %>%
      dplyr::select(-intensity) %>%
      mutate(sat = F) %>%
      mutate(aboveSat = F) %>%
      mutate(value_lat = NA) %>%
      mutate(lat_water = distrWater * latflow_fac) %>%
      mutate(cell_id = paste0(nlayer,"_",column))

## construct database with cell neighbours
celllayer = dplyr::filter(tsx, zgrid == 0) %>%
                 dplyr::select(x,y,column)

# find side cells
cellneig_sides =  as.data.frame(adjacent(rasterFromXYZ(as.data.frame(celllayer)), cell = seq(1,num_cell), directions=4, sorted=TRUE))
cellneig_sides$nums = sequence(rle(cellneig_sides$from)$lengths)
cellneig_sides$columns = paste0("lat_s",cellneig_sides$nums)
# find corner cells
cellneig_corners =  as.data.frame(adjacent(rasterFromXYZ(as.data.frame(celllayer)), cell = seq(1,num_cell), directions="bishop", sorted=TRUE))
cellneig_corners$nums = sequence(rle(cellneig_corners$from)$lengths)
cellneig_corners$columns = paste0("lat_c",cellneig_corners$nums)

# cellneig_sides = spread(cellneig_sides, columns, to, fill=NA)
cellneig_sides = dcast(cellneig_sides, from ~ columns ,fill = NA, value.var = "to")
colnames(cellneig_sides)[1] = "column"
# cellneig_corners = spread(cellneig_corners, columns, to, fill=NA)
cellneig_corners = dcast(cellneig_corners, from ~ columns ,fill = NA, value.var = "to")
colnames(cellneig_corners)[1] = "column"

## join adjacent cells with cell-grid
tsx = left_join(tsx, cellneig_sides) %>%
      dplyr::mutate(lat_s1 = ifelse(!is.na(lat_s1),paste0(nlayer,"_",lat_s1), lat_s1))%>%
      dplyr::mutate(lat_s2 = ifelse(!is.na(lat_s2),paste0(nlayer,"_",lat_s2), lat_s2))%>%
      dplyr::mutate(lat_s3 = ifelse(!is.na(lat_s3),paste0(nlayer,"_",lat_s3), lat_s3))%>%
      dplyr::mutate(lat_s4 = ifelse(!is.na(lat_s4),paste0(nlayer,"_",lat_s4), lat_s4))%>%
      left_join(cellneig_corners) %>%
      dplyr::mutate(lat_c1 = ifelse(!is.na(lat_c1),paste0(nlayer,"_",lat_c1), lat_c1))%>%
      dplyr::mutate(lat_c2 = ifelse(!is.na(lat_c2),paste0(nlayer,"_",lat_c2), lat_c2))%>%
      dplyr::mutate(lat_c3 = ifelse(!is.na(lat_c3),paste0(nlayer,"_",lat_c3), lat_c3))%>%
      dplyr::mutate(lat_c4 = ifelse(!is.na(lat_c4),paste0(nlayer,"_",lat_c4), lat_c4))

## create mass balance error file
mb_error = data.frame(Timestep = seq(1:precip_time), error = NA, corrected = NA)

####################
## start with for loop and TS1
time.s = proc.time()
for(i in 1:precip_time){ 
# for(i in 3:10){ 
  # i=2
## pass previous values to new time step data.frame
tsx$prevalue = tsx$value
# tsx$value = 0
tsx$Timestep = i

## fill cells with water of time step x
####################
## vertical infiltration
## filling is done seperately for macro pore cells and other ("pipe") cells
tsx = dplyr::mutate(tsx, value_macro = ifelse(infProcess == "macro" & nlayer == layerfill, prevalue + (distrWater / cellsLayerColumn), prevalue)) %>%
      dplyr::mutate(value_macro = ifelse(infProcess == "macro", value_macro, 0)) %>%
      ## normal filing
      dplyr::mutate(value_pipe = ifelse(infProcess == "pipe" & nlayer == layerfill, prevalue + (distrWater / cellsLayerColumn) * vertflow_fac, prevalue)) %>%
      ## adjust water amount for "vertically first filled cell", where all column water goes in !!
      dplyr::mutate(value_pipe = ifelse(infProcess == "pipe" & nlayer == layerfill & aboveSat == F, value_pipe + (distrWater / cellsLayerColumn) * (1 - vertflow_fac), value_pipe)) %>%
      dplyr::mutate(value_pipe = ifelse(infProcess == "pipe", value_pipe, 0)) %>%
      dplyr::mutate(value = value_macro + value_pipe)
####################


####################
## lateral water flow
## distribution of water into adjecent neighbouring cells
## all 8 cells in its surounding are considered, distinguishing
## 1) side cells, bordering with a complete cell_width
## 2) corner cells, connecting with the "origin cell" only at its corners
## procedure is:
## 1) find saturated cells
## 2) exclude saturated neighbour-cells
## 3) distribute later water (part of water_vol_min, depending on the factor lat_facflow chosen) into cells
## 4) recombine later water with already existing water in each cell
# sides
lateral_flow_sides = dplyr::filter(tsx, sat == T) %>%
# lateral_flow_sides = dplyr::filter(tt, sat == T) %>%
                    dplyr::select(cell_id, nlayer, lat_water, lat_s1, lat_s2, lat_s3, lat_s4) %>%
                    melt(id=c("cell_id", "lat_water", "nlayer")) #%>%
cnt_NOTna_cells = group_by(lateral_flow_sides, cell_id) %>%
                  dplyr::summarize(num_latcells = length(na.omit(value)))
lateral_flow_sides = left_join(lateral_flow_sides, cnt_NOTna_cells) %>%
                    dplyr::mutate(value_lat = lat_water * sfactor / num_latcells) # %>%
                    # dplyr::mutate(lat_cell = paste0(nlayer,"_",value)) # %>%
                    # dplyr::mutate(org_cell = cell_id)
# corners
lateral_flow_corners = dplyr::filter(tsx, sat == T) %>%
                    dplyr::select(cell_id, nlayer, lat_water, lat_c1, lat_c2, lat_c3, lat_c4) %>%
                    melt(id=c("cell_id", "lat_water", "nlayer")) #%>%
cnt_NOTna_cells = group_by(lateral_flow_corners, cell_id) %>%
                  dplyr::summarize(num_latcells = length(na.omit(value)))
lateral_flow_corners = left_join(lateral_flow_corners, cnt_NOTna_cells) %>%
                    dplyr::mutate(value_lat = lat_water * cfactor / num_latcells) # %>%
                    # dplyr::mutate(lat_cell = paste0(nlayer,"_",value)) # %>%
                    # dplyr::mutate(org_cell = cell_id)
# combine both
lateral_flow_sc = rbind(lateral_flow_sides, lateral_flow_corners)
                    # es muss auch noch geguckt werden, ob alle 4 cells je befüllt werden,
                    # sonst muss noch skaliert werden !!!!
## nach zusammenführen von corner und sides, noch nur 1 value_lat pro cellid schaffen
# lateral_flows = group_by(lateral_flow_sc, lat_cell) %>%
lateral_flows = group_by(lateral_flow_sc, value) %>%
                dplyr::summarize(value_lat = sum(value_lat, na.rm=T)) %>%
                dplyr::mutate(lat_cell = value) %>%
                dplyr::select(lat_cell, value_lat)

tsx = left_join(dplyr::select(tsx, -value_lat), as.data.frame(lateral_flows), by=c("cell_id" = "lat_cell")) %>%
      dplyr::mutate(value = ifelse(is.na(value_lat) | !is.finite(value_lat), value, value + value_lat))
####################

####################
## check mass (water) balance, before saving !!
mb_ts = sum(tsx$value * vol_cell, na.rm = T) - sum(tsx$prevalue * vol_cell, na.rm = T)
mb_error$error[i] = abs(1 - mb_ts / water_vol_min)
# mb_error$corrected[i] = abs(1 - mb_ts / water_vol_min)
# print(error)
## if mass balance error is too big
## adjust distributed water mass in this timestep
## this is done via scaling all distributed water (only of this timestep)
## to match with the available water (water_vol_min)
## this could lead to influenced and "wrong" distribution in cells !?
# while(abs(1 - mb_ts / water_vol_min) < mb_permitted_error){
if(abs(1 - mb_ts / water_vol_min) > mb_permitted_error){
    error_scaling = 1 / (mb_ts / water_vol_min)
    tsx = dplyr::mutate(tsx, value_ts_scaled = (value - prevalue) * error_scaling) %>%
          dplyr::mutate(value = prevalue + value_ts_scaled) %>%
          dplyr::select(-value_ts_scaled)
    ## calculate new mass balance, after re-scaling
    mb_ts_cor = sum(tsx$value * vol_cell, na.rm = T) - sum(tsx$prevalue * vol_cell, na.rm = T)
    mb_error$corrected[i] = abs(1 - mb_ts_cor / water_vol_min)
}

## combine with data from previous time steps
# IN FINAL VERSION: save only selected columns !!! -> memory issue after concating and reading back into R !!
# if(i == 1){
# write.table(tsx, file=paste0(dir_output, "raw/tsx_TS", formatC(i, width=3, flag="0"), ".txt"), sep="\t", row.names=F, col.names=T, append=F)
# }else{
# write.table(tsx, file=paste0(dir_output, "raw/tsx_TS", formatC(i, width=3, flag="0"), ".txt"), sep="\t", row.names=F, col.names=F, append=F)
# }
if(i == 1){
write.table(dplyr::select(tsx, x, y, z, zgrid, value, Timestep), 
            file=paste0(dir_output, "raw/tsx_TS", formatC(i, width=3, flag="0"), ".txt"), sep="\t", row.names=F, col.names=T, append=F)
}else{
write.table(dplyr::select(tsx, x, y, z, zgrid, value, Timestep),
            file=paste0(dir_output, "raw/tsx_TS", formatC(i, width=3, flag="0"), ".txt"), sep="\t", row.names=F, col.names=F, append=F)
}

## transmitting information to adjacent cells about saturation state
## also setting own state sat = T
# cells_sat = dplyr::mutate(tsx, saturated = ifelse(value >= dtheta, T, F)) %>%
            # dplyr::select(tsx, cell_id, nlayer, saturated, lat_s1, lat_s2, lat_s3, lat_s4, lat_c1, lat_c2, lat_c3, lat_c4)
cells_sat = dplyr::filter(tsx, value >= dtheta) %>%
            dplyr::mutate(belowSatnLayer = paste(cell_id,"_", (nlayer + 1))) %>%
            dplyr::select(cell_id, belowSatnLayer, nlayer, column)

# set saturation state of cell
tsx$sat[which(tsx$cell_id %in% cells_sat$cell_id)] = T
# give cell the information if the direct above cell is already saturated
# except for the macro pores
tsx$belowSatnLayer = paste(tsx$cell_id,"_", (tsx$nlayer))
tsx$aboveSat[which(tsx$belowSatnLayer %in% cells_sat$belowSatnLayer & tsx$infProcess != "macro")] = T
# set information NA, if neighbour cell is already saturated
tsx$lat_s1[which(tsx$lat_s1 %in% cells_sat$cell_id)] = NA
tsx$lat_s2[which(tsx$lat_s2 %in% cells_sat$cell_id)] = NA
tsx$lat_s3[which(tsx$lat_s3 %in% cells_sat$cell_id)] = NA
tsx$lat_s4[which(tsx$lat_s4 %in% cells_sat$cell_id)] = NA
tsx$lat_c1[which(tsx$lat_c1 %in% cells_sat$cell_id)] = NA
tsx$lat_c2[which(tsx$lat_c2 %in% cells_sat$cell_id)] = NA
tsx$lat_c3[which(tsx$lat_c3 %in% cells_sat$cell_id)] = NA
tsx$lat_c4[which(tsx$lat_c4 %in% cells_sat$cell_id)] = NA

## determine which vertical cell of a column gets filled in the next timestep
## depends on saturation state of cell
layerfilling = dplyr::mutate(tsx, unsaturated = ifelse(sat, 10000, nlayer)) %>%
               group_by(column, infProcess) %>%
               dplyr::summarize(layerfill = min(unsaturated, na.rm=T))
tsx = dplyr::select(tsx, - layerfill) %>%
      inner_join(layerfilling)

## determine the number of cells in each column, which are to be filled in the next timestep
## this value is used to divide the avaivable water per timestep
## and thus directly influences errors in mass balance
cellnums_dynamic = dplyr::mutate(layerfilling, ncells = ifelse(infProcess == "macro" & layerfill < 2, mdepth * 10 +1, 0)) %>%
                   dplyr::mutate(ncells = ifelse(infProcess == "pipe", 1, ncells)) %>%
                   dplyr::group_by(column) %>%
                   dplyr::summarize(cellsLayerColumn = sum(ncells, na.rm=T))
tsx = dplyr::select(tsx, - cellsLayerColumn) %>%
      inner_join(cellnums_dynamic)

} # end for loop
time.e = proc.time()
print("model ascii files")
print(time.e - time.s)

## save mass balance error log
save(mb_error, file=paste0(dir_output, "MassBalanceError_", n_param, ".rdata"))

# # ####################
# # ## debugging
# # i = 360
# # load(file=paste0(dir_output, "/scenarios/combiExt/tsx_TS", i, ".rdata"))
# # sum(tsx$value) * vol_cell
# # watbal = data.frame(Timestep = 1:360, val=0)
# # for(i in 1:360){
# # for(i in 1:precip_time){
# # load(file=paste0(dir_output, "/scenarios/combiExt/tsx_TS", i, ".rdata"))
# # # water irrigated this timestep
# # val = sum(tsx$value) / i * vol_cell
# # watbal$Timestep[i] = i
# # watbal$val[i] = val
# # }
# # watbal$cumval = cumsum(watbal$val)
# # # plot vertical water distribution
# # cutrel = 8
# # cutposition = min(tsx$y) + cutrel
# # data_plot = dplyr::filter(tsx, y == cutposition)
# # maxy = max(data_plot$zgrid, na.rm=T)
# # ggplot(data_plot, aes(x = x, y = zgrid)) + geom_raster(aes(fill = value)) + ylim(maxy,0) + 
# # theme(legend.position="right") +
# # ylab("Depth [m]") + xlab("x [m]") + 
# # scale_fill_gradientn(colours = rev(viridis(7)))
# # ####################
# #               
# # print("finished modeling")
# print("starting data loading and stichting")
# # ####################
# # ## load and stich all datasets
# # ## define empty result data.frame
# # Irrigation_macropiping = data.frame()
# # 
# # for(i in 1:precip_time){
# # load(file=paste0(dir_output, "tsx_paramset_", n_param, "_TS", i, ".rdata"))
# # Irrigation_macropiping = rbind(Irrigation_macropiping, tsx)
# # }
# # print("finished data loading and stichting")
# # ## remove indexing, not needed columns (to save space)
# # # Irrigation_macropiping = dplyr::select(Irrigation_macropiping, - cnt, - layerfill)
# 
####################
## stich ascii files using bash
time.s = proc.time()
print("stiching output files")
systemcall_stich = paste0("cat ", dir_output, "raw/*.txt > ", dir_output, "raw/rawdata")
#system("cat /home/hydro/mreich/Irrigation/output/modbased/raw/*.txt > /home/hydro/mreich/Irrigation/output/modbased/raw/rawdata")
system(systemcall_stich)
time.e = proc.time()
print(time.e - time.s)
####################
## load stitched file
time.s = proc.time()
print("read stiched output files")
# regular read.table
# Irrigation_macropiping = read.table(file=paste0(dir_output, "raw/rawdata.txt"), header = F, sep="\t", dec=".")
# colnames(Irrigation_macropiping) = tsx_header
# data.tables fread
Irrigation_macropiping = fread(file=paste0(dir_output, "raw/rawdata"), header = T, sep="\t", dec=".", 
                               ## read only columns needed
                               select = c("x","y","z","zgrid","value","Timestep"))
## convert data.table to data.frame
setDF(Irrigation_macropiping)
time.e = proc.time()
print(time.e - time.s)

####################
## check if all water was actually distributed
# water_bal = group_by(Irrigation_macropiping, Timestep) %>%
#                 dplyr::summarize(water_distributed = sum(value / Timestep, na.rm = T) * vol_cell)
# save(water_bal, file=paste0(dir_output,"water_bal_", n_param, ".rdata"))

####################
## reasonability checks ("sub"-unit testing on scenario basis)
# check total water of system
print("water balance MACROPORES & PIPING:")
# print( checkWaterVolumes(Irrigation_macropiping, "totalwater", precip_time, vol_cell, water_vol_min) )
# # check water of each timestep
# # check water of one timestep
checkTS = precip_time
# checkTS = 50
# print("water balance PISTON FLOW (ts = 360):")
checkWaterVolumes(Irrigation_macropiping, "tswater", precip_time, vol_cell, water_vol_min, checkTS)
plots=F
print(checkWaterVolumes(Irrigation_macropiping, "waterpertimestep", precip_time, vol_cell, water_vol_min, plotting=plots))
# plot
png(file=paste0(dir_plots, "Distribution_simple_macropiping_mean_", n_param, ".png"), width=1000, height=1000, res=250)
print(plotInfWater(Irrigation_macropiping, "means"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_max_", n_param, ".png"), width=1000, height=1000, res=250)
print(plotInfWater(Irrigation_macropiping, "theta"))
dev.off()

##########
# load(file=paste0(dir_output, "Irrigation_combiExt_macropiping_", n_param, ".rdata"))
# plot profile (along x)
# igrav_x = 4564082.00
# igrav_y = 5445669.70
yrel = 8 # [m]
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs60_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 60, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs120_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 120, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs180_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 180, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs240_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 240, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs300_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 300, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs360_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 360, yrel, "x"))
dev.off()

print(paste0("Saving Irrigation data for n_param: ", n_param))
## save data
save(Irrigation_macropiping, file=paste0(dir_output, "Irrigation_combiExt_macropiping_", n_param, ".rdata"))

# 
##debug
#load data
# load(file=paste0(dir_output, "Irrigation_combiExt_macropiping_", n_param, ".rdata"))
# print(str(Irrigation_macropiping))
# print(str(gcomp_irrigation_domain))
# tt =dplyr::select(Irrigation_macropiping, x,y,z,value,Timestep)
# print(str(tt))
# print(range(tt$Timestep))
# ttt = left_join(gcomp_irrigation_domain, tt)
# print(str(ttt))
# print(range(ttt$Timestep))
# print(range(ttt$value))
# print("other test irrigation dataset:")
# load(file="/home/hydro/mreich/Irrigation/output/combi/Irrigation_simple_macropiping.rdata")
# print("-zgrid")
# tt =dplyr::select(Irrigation_macropiping, -zgrid)
# print(str(tt))
# ttt = left_join(gcomp_irrigation_domain, tt)
# print(str(ttt))
# print("select positiv")
# tt =dplyr::select(Irrigation_macropiping, x,y,z,value,Timestep)
# print(str(tt))
# ttt = left_join(gcomp_irrigation_domain, tt)
# print(str(ttt))

########################################
## gravity response in nm/s²
########################################
## !!
## due to saving into ascii, reading and stiching (within the processing procedure)
## joining columns (x,y,z) have to be rounded! in order to match with gravity component grid
## !!
Irrigation_macropiping$x = round(Irrigation_macropiping$x,2)
Irrigation_macropiping$y = round(Irrigation_macropiping$y,2)
Irrigation_macropiping$z = round(Irrigation_macropiping$z,2)
gcomp_irrigation_domain$x = round(gcomp_irrigation_domain$x,2)
gcomp_irrigation_domain$y = round(gcomp_irrigation_domain$y,2)
gcomp_irrigation_domain$z = round(gcomp_irrigation_domain$z,2)

# should timesteps or POSIXct units be shown on x-axis?
showRealdates = F
# gsignal_irrigation_macropiping = gsignal_grids_3d(gcomp_irrigation_domain, dplyr::select(Irrigation_macropiping, -zgrid), showRealdates)
print("calculating gravity response..")
gsignal_irrigation_macropiping = gsignal_grids_3d(gcomp_irrigation_domain, dplyr::select(Irrigation_macropiping, x,y,z,value,Timestep), showRealdates)
#save gsignal
save(gsignal_irrigation_macropiping, file=paste0(dir_output, "gmod_Irrigation_macropiping_", n_param, ".rdata"))
# print(str(gsignal_irrigation_macropiping))

## combine datasets and plot
gmod = rbind(
         cbind(igrav_timesteps, Scenario="iGrav (observed)"),
	     cbind(gsignal_irrigation_macropiping, Scenario="Macro & Piping")
         )

png(file=paste0(dir_plots, "gmod_signal_Irrigation_combinedExtScenarios_macropipe_", n_param, ".png"), width=1500, height=1000, res=250)
plot(ggplot(gmod, aes(x=Timestep, y=gmod, colour=Scenario)) + geom_line() + 
	ylab("Gravity [nm/s²]") + xlab("Time since irrigation start [min]"))
dev.off()

####################
## calculate fit to gobs

## regular KGE
# kge_value = KGE(gsignal_irrigation_macropiping$gmod, igrav_timesteps$gmod)
## changing scaling factor of component BIAS
kge_value = KGE(gsignal_irrigation_macropiping$gmod, igrav_timesteps$gmod, s=c(2.5/6,2.5/6,1/6))
kge_fit = 1 - kge_value

####################
## clean up memory
rm(Irrigation_macropiping, gsignal_irrigation_macropiping)
gc()
## move to next n_param value for plot indexing
n_param <<- n_param + 1

## returning quality criteria:
## KGE
return(kge_fit) 

## else statement, runs if pipedepth > mdepth
}

print("finished MACROPORES & PIPING !")
####################
} # end of function

#' @title Hydro-gravimetric model (incl. lateral flow), for 2 different macro pore layers
#'
#' @description 3D distribution algorithm, modeling the soil infiltration of water from a sprinkling experiment
#'
#' @param paramvec Numeric vector, proving input in this EXACT ORDER of the parameter values: saturation deficit of 1st process (macro pores), saturation deficit of 2nd process, total vertical thickness (extent) of 1st process (macropores), scaling factor (0 to 1) defining the relatinship between lateral and vertical flow after saturation of a cell.
#' @param test
#' @param test
#' ...
#' @details The function was written to be easily usable together with optimization tools.
#' It thus  needs a configfile.rdata-file with the following columns, each consisting of one single value:
#' dir_input, dir_output, precip_time, IntensityDistributionution, water_vol_min, gcompfile, gravityObs, mb_permitted_error.

#' @references Marvin Reich (2016), mreich@@gfz-potsdam.de
#' @examples missing

inf_model_3d_2macro = function(param_vec){

##########################################
## directories
##########################################
# # local
# dir_input = "/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/"
# dir_output = "/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/"
# dir_plots = "/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/plots/"
# cluster
# dir_plots = paste0(dir_output,"plots/")

##########################################
## scenario properties
# should a water distribution be used?
# IntensityDistribution = "homo"
# IntensityDistribution = Intensity_distribution
# IntensityDistribution = "ideal"
##########################################

##########################################
## load infiltration data
##########################################

print("start calculatings for infiltration: COMBINED Extended scenarios..")

# ####################
# ## debugging
# library(dplyr)
# library(reshape2)
# library(raster)
# library(tidyr)
# dir_output = "/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/"
# load(file="/home/mreich/Dokumente/written/beregnungsPaper/data/output/irrigation/Intensity_distribution_real_IDW.rdata")
# load(file="/home/mreich/Dokumente/written/beregnungsPaper/data/output/gravity/grids/gridcells.rdata")
# load(file="/home/mreich/Dokumente/written/beregnungsPaper/data/output/gravity/grids/gcomp_irrigation_domain_allValid_3m.rdata")
# precip_time = 360
# exp3_meta = read.table(file="/home/mreich/Dokumente/written/beregnungsPaper/data/input/Irrigation/Irrigation_precondition_dry", skip= 5, nrows=8, dec=".", colClasses = character(), stringsAsFactors=F)
# water_total_experiment = as.numeric(exp3_meta[6,2]) + as.numeric(exp3_meta[7,2]) # [m³]
# water_vol_min = water_total_experiment / precip_time #[m³/min]
# zlayers = round(seq(0,3, by=.1),1)
# # params
# dtheta_macro = 0.1
# dtheta_macro2 = 0.000000005
# dtheta_pipe = 0.01
# mdepth = 0.3
# mdepth2 = 1 
# pipedepth = 0.6
# latflow_fac = 0.5
# mb_permitted_error = 0.05
# vertflow_fac = 1 - latflow_fac
# vol_cell = 0.1 * 0.1 * 0.1 # [m³]
# Irrigation_grid = dplyr::select(gcomp_irrigation_domain, x,y,z,zgrid)
# zlayers = round(unique(Irrigation_grid$zgrid),1)
# num_cell = length(unique(Irrigation_grid$x)) *  length(unique(Irrigation_grid$y))
# cfactor = 0.4
# sfactor = 1 - cfactor
# dir_output = "/home/mreich/temp/"
# ####################

# ##########
# ## logging to file
# logfile = paste0("irrigation zgrid: ",unique(Irrigation_in$zgrid))
# write.table(logfile, file=paste0(dir_output, "logfile"), append=T)
# ##########

###################
## load model configuration
load(file="configfile.rdata")
dir_input = configfile$dir_input
dir_output = configfile$dir_output
precip_time = configfile$precip_time
IntensityDistribution = configfile$IntensityDistribution
water_vol_min = configfile$water_vol_min
gcompfile = configfile$gcompfile
gravityObs = configfile$gravityObs
mb_permitted_error = configfile$mb_permitted_error

# setting plot directory
dir_plots = paste0(dir_output,"plots/")

# volume of grid cell 
vol_cell = 0.1 * 0.1 * 0.1 # [m³]
# gridcells
load(file=paste0(dir_input, "gridcells.rdata"))

## load gravity calculation data
# load gravity effect grid
load(file=paste0(dir_input, gcompfile))
# load igrav time series in same period
load(file=paste0(dir_input, gravityObs))
# set same column name for joining datasets
colnames(igrav_exp3)[2] = "gmod"
igrav_exp3_cor = mutate(igrav_exp3, gmod = gmod - min(gmod))
igrav_timesteps = data.frame(Timestep = 1:length(igrav_exp3_cor$gmod[-1]), gmod = igrav_exp3_cor$gmod[-1])

Irrigation_grid = dplyr::select(gcomp_irrigation_domain, x,y,z,zgrid)

# vertical layers
zlayers = round(unique(Irrigation_grid$zgrid),1)
# number of cells per layer
num_cell = length(unique(Irrigation_grid$x)) *  length(unique(Irrigation_grid$y))

# define factors for scaling between "side" and "corner" cell neighbours
# following (Quinn 1997), where cardinal (side) and diagnol (corner) factors are summed
# all 8 cells are delivered thus leading to the following factors
# for side cells
# 4 * 0.5/SUM(all factors for all cells) = 4 * 0.15
sfactor = 0.6
# for corner cells
# 4 * 0.35/SUM(all factors for all cells) = 4 * 0.1
cfactor = 0.4

# ##########
# ## logging to file
# logfile = paste0("irrigation zgrid: ",unique(Irrigation_in$zgrid))
# write.table(logfile, file=paste0(dir_output, "logfile"), append=T)
# ##########

##########################################
## set scenario settings: intensity distribution
switch(IntensityDistribution,
       ideal = {
          load(file=paste0(dir_input, "Intensity_distribution_ideal_IDW.rdata"))
          # Irrigation_in = inner_join(Irrigation_in, Intensity_distribution)
       },
       real = {
          load(file=paste0(dir_input, "Intensity_distribution_real_IDW.rdata"))
          # Irrigation_in = inner_join(Irrigation_in, Intensity_distribution)
       }
)
##########################################

####################
## prepare statistis outout
stats = data.frame()
####################

print("Finished loading setup parameters.")

##########################################
## pass parameters from DDS-function param_vec space
##########################################
dtheta_macro = param_vec[1]
dtheta_macro2 = param_vec[2]
dtheta_pipe = param_vec[3]
# parameter values in meters have to be rounded
# otherwise values will NOT match grid discretization !!
mdepth = round(param_vec[4],1)
mdepth2 = round(param_vec[5],1)
# somewhere define that pipedepth > mdepth !!
# now pipedepth is directly below the macro pore layer
# pipedepth = round(mdepth + 0.1, 1)
# pipedepth is set individually
# this allows a space between macro pore layer and 2nd process
# pipedepth = round(param_vec[6],1)
# lateral flow factor (seperate into lateral and vertical flow)
latflow_fac = param_vec[6]
vertflow_fac = 1 - latflow_fac

####################
## check validity of chosen thicknesses / depth of both infiltration processes
# if(pipedepth <= mdepth){
#   kge_fit = 1
#   return(kge_fit) 
# # if everything is okay, run normally
# }else{ 

if(mdepth2 <= mdepth){
  kge_fit = 1
  return(kge_fit) 
# if everything is okay, run normally
}else{ 

##########################################
## build up model domain space

# depth of macropore layer thickness
# mdepth = .3 # [m]
# determine vertical start
mdepth_layer = which(zlayers == mdepth)
mdepth2_layer = which(zlayers == mdepth2)
# print(mdepth_layer)
# print(zlayers)
# print(dtheta_macro)
# print(dtheta_pipe)

# # depth of pipe routing
pipedepth = mdepth2 + 0.1 # [m]
# pipedepth = 0.8  # [m]
# determine vertical start
# pipe_layer = which(zlayers == pipedepth)
## how many layers are between macro and pipe process?
# layer_between = pipe_layer - mdepth_layer - 1
macro_layer_between = mdepth2_layer - mdepth_layer
# ####################
# 
tsx = dplyr::mutate(Irrigation_grid,
      column = rep(gridcells$ncell, length(zlayers))) %>%
      dplyr::mutate(cnt = 1) %>%
      dplyr::mutate(Timestep = 0) %>%
      dplyr::mutate(value = 0) %>%
      dplyr::mutate(prevalue = 0)

## tag vertical layers with infiltration process
layer_params = data.frame(zgrid = zlayers,
                         infProcess = c(rep("macro", mdepth_layer),rep("macro2", macro_layer_between), rep("pipe",(length(zlayers) - mdepth2_layer))),
                         nlayer = c(rep(1,mdepth_layer), rep(1, macro_layer_between), seq(1,length.out=(length(zlayers) - mdepth2_layer))),
                         # nlayer = c(rep(1,mdepth_layer), seq(1,length.out=(length(zlayers) - mdepth_layer))),
                         dtheta = c(rep(dtheta_macro,mdepth_layer),rep(dtheta_macro2,macro_layer_between),rep(dtheta_pipe,(length(zlayers) - mdepth2_layer)))
              )

## tag cells with layer parameters
tsx = inner_join(tsx, layer_params) # %>%
      # inner_join(Irrigation_grid)

## calculate number of "same" cells per layers in a column
cellnums = group_by(tsx, column, nlayer) %>%
# cellnums = group_by(tsx, column, nlayer, infProcess) %>%
           dplyr::summarize(cellsLayerColumn = sum(cnt, na.rm=T)) %>%
           ungroup()

## join with intensity distribution coefficents
tsx = inner_join(tsx, Intensity_distribution) %>%
      mutate(distrWater = water_vol_min * intensity / num_cell / vol_cell) %>%
      mutate(layerfill = 1) %>%
      inner_join(cellnums) %>%
      dplyr::select(-intensity) %>%
      mutate(sat = F) %>%
      mutate(aboveSat = F) %>%
      mutate(value_lat = NA) %>%
      mutate(lat_water = distrWater * latflow_fac) %>%
      mutate(cell_id = paste0(nlayer,"_",column,"_",infProcess))

## construct database with cell neighbours
celllayer = dplyr::filter(tsx, zgrid == 0) %>%
                 dplyr::select(x,y,column)

# find side cells
cellneig_sides =  as.data.frame(adjacent(rasterFromXYZ(as.data.frame(celllayer)), cell = seq(1,num_cell), directions=4, sorted=TRUE))
cellneig_sides$nums = sequence(rle(cellneig_sides$from)$lengths)
cellneig_sides$columns = paste0("lat_s",cellneig_sides$nums)
# find corner cells
cellneig_corners =  as.data.frame(adjacent(rasterFromXYZ(as.data.frame(celllayer)), cell = seq(1,num_cell), directions="bishop", sorted=TRUE))
cellneig_corners$nums = sequence(rle(cellneig_corners$from)$lengths)
cellneig_corners$columns = paste0("lat_c",cellneig_corners$nums)

# cellneig_sides = spread(cellneig_sides, columns, to, fill=NA)
cellneig_sides = dcast(cellneig_sides, from ~ columns ,fill = NA, value.var = "to")
colnames(cellneig_sides)[1] = "column"
# cellneig_corners = spread(cellneig_corners, columns, to, fill=NA)
cellneig_corners = dcast(cellneig_corners, from ~ columns ,fill = NA, value.var = "to")
colnames(cellneig_corners)[1] = "column"

## join adjacent cells with cell-grid
tsx = left_join(tsx, cellneig_sides) %>%
      dplyr::mutate(lat_s1 = ifelse(!is.na(lat_s1),paste0(nlayer,"_",lat_s1), lat_s1))%>%
      dplyr::mutate(lat_s2 = ifelse(!is.na(lat_s2),paste0(nlayer,"_",lat_s2), lat_s2))%>%
      dplyr::mutate(lat_s3 = ifelse(!is.na(lat_s3),paste0(nlayer,"_",lat_s3), lat_s3))%>%
      dplyr::mutate(lat_s4 = ifelse(!is.na(lat_s4),paste0(nlayer,"_",lat_s4), lat_s4))%>%
      left_join(cellneig_corners) %>%
      dplyr::mutate(lat_c1 = ifelse(!is.na(lat_c1),paste0(nlayer,"_",lat_c1), lat_c1))%>%
      dplyr::mutate(lat_c2 = ifelse(!is.na(lat_c2),paste0(nlayer,"_",lat_c2), lat_c2))%>%
      dplyr::mutate(lat_c3 = ifelse(!is.na(lat_c3),paste0(nlayer,"_",lat_c3), lat_c3))%>%
      dplyr::mutate(lat_c4 = ifelse(!is.na(lat_c4),paste0(nlayer,"_",lat_c4), lat_c4))

## create mass balance error file
mb_error = data.frame(Timestep = seq(1:precip_time), error = NA, corrected = NA)

####################
## start with for loop and TS1
time.s = proc.time()
for(i in 1:precip_time){ 
# for(i in 3:10){ 
  # i=2
## pass previous values to new time step data.frame
tsx$prevalue = tsx$value
# tsx$value = 0
tsx$Timestep = i

## fill cells with water of time step x
####################
## vertical infiltration
## filling is done seperately for macro pore cells and other ("pipe") cells
tsx = dplyr::mutate(tsx, value_macro = ifelse(infProcess == "macro" & nlayer == layerfill, prevalue + (distrWater / cellsLayerColumn), prevalue)) %>%
      dplyr::mutate(value_macro = ifelse(infProcess == "macro2" & nlayer == layerfill, prevalue + (distrWater / cellsLayerColumn), value_macro)) %>%
      dplyr::mutate(value_macro = ifelse(infProcess == "macro" | infProcess == "macro2", value_macro, 0)) %>%
      ## normal filing
      dplyr::mutate(value_pipe = ifelse(infProcess == "pipe" & nlayer == layerfill, prevalue + (distrWater / cellsLayerColumn) * vertflow_fac, prevalue)) %>%
      ## adjust water amount for "vertically first filled cell", where all column water goes in !!
      dplyr::mutate(value_pipe = ifelse(infProcess == "pipe" & nlayer == layerfill & aboveSat == F, value_pipe + (distrWater / cellsLayerColumn) * (1 - vertflow_fac), value_pipe)) %>%
      dplyr::mutate(value_pipe = ifelse(infProcess == "pipe", value_pipe, 0)) %>%
      dplyr::mutate(value = value_macro + value_pipe)
####################

####################
## lateral water flow
## distribution of water into adjecent neighbouring cells
## all 8 cells in its surounding are considered, distinguishing
## 1) side cells, bordering with a complete cell_width
## 2) corner cells, connecting with the "origin cell" only at its corners
## procedure is:
## 1) find saturated cells
## 2) exclude saturated neighbour-cells
## 3) distribute later water (part of water_vol_min, depending on the factor lat_facflow chosen) into cells
## 4) recombine later water with already existing water in each cell
# sides
lateral_flow_sides = dplyr::filter(tsx, sat == T) %>%
# lateral_flow_sides = dplyr::filter(tt, sat == T) %>%
                    dplyr::select(cell_id, nlayer, lat_water, lat_s1, lat_s2, lat_s3, lat_s4) %>%
                    melt(id=c("cell_id", "lat_water", "nlayer")) #%>%
cnt_NOTna_cells = group_by(lateral_flow_sides, cell_id) %>%
                  dplyr::summarize(num_latcells = length(na.omit(value)))
lateral_flow_sides = left_join(lateral_flow_sides, cnt_NOTna_cells) %>%
                    dplyr::mutate(value_lat = lat_water * sfactor / num_latcells) # %>%
                    # dplyr::mutate(lat_cell = paste0(nlayer,"_",value)) # %>%
                    # dplyr::mutate(org_cell = cell_id)
# corners
lateral_flow_corners = dplyr::filter(tsx, sat == T) %>%
                    dplyr::select(cell_id, nlayer, lat_water, lat_c1, lat_c2, lat_c3, lat_c4) %>%
                    melt(id=c("cell_id", "lat_water", "nlayer")) #%>%
cnt_NOTna_cells = group_by(lateral_flow_corners, cell_id) %>%
                  dplyr::summarize(num_latcells = length(na.omit(value)))
lateral_flow_corners = left_join(lateral_flow_corners, cnt_NOTna_cells) %>%
                    dplyr::mutate(value_lat = lat_water * cfactor / num_latcells) # %>%
                    # dplyr::mutate(lat_cell = paste0(nlayer,"_",value)) # %>%
                    # dplyr::mutate(org_cell = cell_id)
# combine both
lateral_flow_sc = rbind(lateral_flow_sides, lateral_flow_corners)
                    # es muss auch noch geguckt werden, ob alle 4 cells je befüllt werden,
                    # sonst muss noch skaliert werden !!!!
## nach zusammenführen von corner und sides, noch nur 1 value_lat pro cellid schaffen
# lateral_flows = group_by(lateral_flow_sc, lat_cell) %>%
lateral_flows = group_by(lateral_flow_sc, value) %>%
                dplyr::summarize(value_lat = sum(value_lat, na.rm=T)) %>%
                dplyr::mutate(lat_cell = value) %>%
                dplyr::select(lat_cell, value_lat)

tsx = left_join(dplyr::select(tsx, -value_lat), as.data.frame(lateral_flows), by=c("cell_id" = "lat_cell")) %>%
      dplyr::mutate(value = ifelse(is.na(value_lat) | !is.finite(value_lat), value, value + value_lat))
####################

####################
## check mass (water) balance, before saving !!
mb_ts = sum(tsx$value * vol_cell, na.rm = T) - sum(tsx$prevalue * vol_cell, na.rm = T)
mb_error$error[i] = abs(1 - mb_ts / water_vol_min)
# mb_error$corrected[i] = abs(1 - mb_ts / water_vol_min)
# print(error)
## if mass balance error is too big
## adjust distributed water mass in this timestep
## this is done via scaling all distributed water (only of this timestep)
## to match with the available water (water_vol_min)
## this could lead to influenced and "wrong" distribution in cells !?
# while(abs(1 - mb_ts / water_vol_min) < mb_permitted_error){
if(abs(1 - mb_ts / water_vol_min) > mb_permitted_error){
    error_scaling = 1 / (mb_ts / water_vol_min)
    tsx = dplyr::mutate(tsx, value_ts_scaled = (value - prevalue) * error_scaling) %>%
          dplyr::mutate(value = prevalue + value_ts_scaled) %>%
          dplyr::select(-value_ts_scaled)
    ## calculate new mass balance, after re-scaling
    mb_ts_cor = sum(tsx$value * vol_cell, na.rm = T) - sum(tsx$prevalue * vol_cell, na.rm = T)
    mb_error$corrected[i] = abs(1 - mb_ts_cor / water_vol_min)
}

## combine with data from previous time steps
# IN FINAL VERSION: save only selected columns !!! -> memory issue after concating and reading back into R !!
# if(i == 1){
# write.table(tsx, file=paste0(dir_output, "raw/tsx_TS", formatC(i, width=3, flag="0"), ".txt"), sep="\t", row.names=F, col.names=T, append=F)
# }else{
# write.table(tsx, file=paste0(dir_output, "raw/tsx_TS", formatC(i, width=3, flag="0"), ".txt"), sep="\t", row.names=F, col.names=F, append=F)
# }
if(i == 1){
write.table(dplyr::select(tsx, x, y, z, zgrid, value, Timestep), 
            file=paste0(dir_output, "raw/tsx_TS", formatC(i, width=3, flag="0"), ".txt"), sep="\t", row.names=F, col.names=T, append=F)
}else{
write.table(dplyr::select(tsx, x, y, z, zgrid, value, Timestep),
            file=paste0(dir_output, "raw/tsx_TS", formatC(i, width=3, flag="0"), ".txt"), sep="\t", row.names=F, col.names=F, append=F)
}

## transmitting information to adjacent cells about saturation state
## also setting own state sat = T
# cells_sat = dplyr::mutate(tsx, saturated = ifelse(value >= dtheta, T, F)) %>%
            # dplyr::select(tsx, cell_id, nlayer, saturated, lat_s1, lat_s2, lat_s3, lat_s4, lat_c1, lat_c2, lat_c3, lat_c4)
cells_sat = dplyr::filter(tsx, value >= dtheta) %>%
            dplyr::mutate(belowSatnLayer = paste(cell_id,"_", (nlayer + 1))) %>%
            dplyr::select(cell_id, belowSatnLayer, nlayer, column)

# set saturation state of cell
tsx$sat[which(tsx$cell_id %in% cells_sat$cell_id)] = T
# give cell the information if the direct above cell is already saturated
# except for the macro pores
tsx$belowSatnLayer = paste(tsx$cell_id,"_", (tsx$nlayer))
tsx$aboveSat[which(tsx$belowSatnLayer %in% cells_sat$belowSatnLayer & tsx$infProcess != "macro" & tsx$infProcess != "macro2")] = T
# set information NA, if neighbour cell is already saturated
tsx$lat_s1[which(tsx$lat_s1 %in% cells_sat$cell_id)] = NA
tsx$lat_s2[which(tsx$lat_s2 %in% cells_sat$cell_id)] = NA
tsx$lat_s3[which(tsx$lat_s3 %in% cells_sat$cell_id)] = NA
tsx$lat_s4[which(tsx$lat_s4 %in% cells_sat$cell_id)] = NA
tsx$lat_c1[which(tsx$lat_c1 %in% cells_sat$cell_id)] = NA
tsx$lat_c2[which(tsx$lat_c2 %in% cells_sat$cell_id)] = NA
tsx$lat_c3[which(tsx$lat_c3 %in% cells_sat$cell_id)] = NA
tsx$lat_c4[which(tsx$lat_c4 %in% cells_sat$cell_id)] = NA

## determine which vertical cell of a column gets filled in the next timestep
## depends on saturation state of cell
layerfilling = dplyr::mutate(tsx, unsaturated = ifelse(sat, 10000, nlayer)) %>%
               group_by(column, infProcess) %>%
               dplyr::summarize(layerfill = min(unsaturated, na.rm=T))
tsx = dplyr::select(tsx, - layerfill) %>%
      inner_join(layerfilling)

## determine the number of cells in each column, which are to be filled in the next timestep
## this value is used to divide the avaivable water per timestep
## and thus directly influences errors in mass balance
cellnums_dynamic = dplyr::mutate(layerfilling, ncells = ifelse(infProcess == "macro" & layerfill < 2, mdepth * 10 +1, 0)) %>%
                   dplyr::mutate(ncells = ifelse(infProcess == "macro2" & layerfill < 2, (mdepth2 - mdepth) * 10, ncells)) %>%
                   dplyr::mutate(ncells = ifelse(infProcess == "pipe", 1, ncells)) %>%
                   dplyr::group_by(column) %>%
                   dplyr::summarize(cellsLayerColumn = sum(ncells, na.rm=T))
tsx = dplyr::select(tsx, - cellsLayerColumn) %>%
      inner_join(cellnums_dynamic)

} # end for loop
time.e = proc.time()
print("model ascii files")
print(time.e - time.s)

## save mass balance error log
save(mb_error, file=paste0(dir_output, "MassBalanceError_", n_param, ".rdata"))

# # ####################
# # ## debugging
# # i = 360
# # load(file=paste0(dir_output, "/scenarios/combiExt/tsx_TS", i, ".rdata"))
# # sum(tsx$value) * vol_cell
# # watbal = data.frame(Timestep = 1:360, val=0)
# # for(i in 1:360){
# # for(i in 1:precip_time){
# # load(file=paste0(dir_output, "/scenarios/combiExt/tsx_TS", i, ".rdata"))
# # # water irrigated this timestep
# # val = sum(tsx$value) / i * vol_cell
# # watbal$Timestep[i] = i
# # watbal$val[i] = val
# # }
# # watbal$cumval = cumsum(watbal$val)
# # # plot vertical water distribution
# # cutrel = 8
# # cutposition = min(tsx$y) + cutrel
# # data_plot = dplyr::filter(tsx, y == cutposition)
# # maxy = max(data_plot$zgrid, na.rm=T)
# # ggplot(data_plot, aes(x = x, y = zgrid)) + geom_raster(aes(fill = value)) + ylim(maxy,0) + 
# # theme(legend.position="right") +
# # ylab("Depth [m]") + xlab("x [m]") + 
# # scale_fill_gradientn(colours = rev(viridis(7)))
# # ####################
# #               
# # print("finished modeling")
# print("starting data loading and stichting")
# # ####################
# # ## load and stich all datasets
# # ## define empty result data.frame
# # Irrigation_macropiping = data.frame()
# # 
# # for(i in 1:precip_time){
# # load(file=paste0(dir_output, "tsx_paramset_", n_param, "_TS", i, ".rdata"))
# # Irrigation_macropiping = rbind(Irrigation_macropiping, tsx)
# # }
# # print("finished data loading and stichting")
# # ## remove indexing, not needed columns (to save space)
# # # Irrigation_macropiping = dplyr::select(Irrigation_macropiping, - cnt, - layerfill)
# 
####################
## stich ascii files using bash
time.s = proc.time()
print("stiching output files")
systemcall_stich = paste0("cat ", dir_output, "raw/*.txt > ", dir_output, "raw/rawdata")
#system("cat /home/hydro/mreich/Irrigation/output/modbased/raw/*.txt > /home/hydro/mreich/Irrigation/output/modbased/raw/rawdata")
system(systemcall_stich)
time.e = proc.time()
print(time.e - time.s)
####################
## load stitched file
time.s = proc.time()
print("read stiched output files")
# regular read.table
# Irrigation_macropiping = read.table(file=paste0(dir_output, "raw/rawdata.txt"), header = F, sep="\t", dec=".")
# colnames(Irrigation_macropiping) = tsx_header
# data.tables fread
Irrigation_macropiping = fread(file=paste0(dir_output, "raw/rawdata"), header = T, sep="\t", dec=".", 
                               ## read only columns needed
                               select = c("x","y","z","zgrid","value","Timestep"))
## convert data.table to data.frame
setDF(Irrigation_macropiping)
time.e = proc.time()
print(time.e - time.s)

####################
## check if all water was actually distributed
# water_bal = group_by(Irrigation_macropiping, Timestep) %>%
#                 dplyr::summarize(water_distributed = sum(value / Timestep, na.rm = T) * vol_cell)
# save(water_bal, file=paste0(dir_output,"water_bal_", n_param, ".rdata"))

####################
## reasonability checks ("sub"-unit testing on scenario basis)
# check total water of system
print("water balance MACROPORES & PIPING:")
# print( checkWaterVolumes(Irrigation_macropiping, "totalwater", precip_time, vol_cell, water_vol_min) )
# # check water of each timestep
# # check water of one timestep
checkTS = precip_time
# checkTS = 50
# print("water balance PISTON FLOW (ts = 360):")
checkWaterVolumes(Irrigation_macropiping, "tswater", precip_time, vol_cell, water_vol_min, checkTS)
plots=F
print(checkWaterVolumes(Irrigation_macropiping, "waterpertimestep", precip_time, vol_cell, water_vol_min, plotting=plots))
# plot
png(file=paste0(dir_plots, "Distribution_simple_macropiping_mean_", n_param, ".png"), width=1000, height=1000, res=250)
print(plotInfWater(Irrigation_macropiping, "means"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_max_", n_param, ".png"), width=1000, height=1000, res=250)
print(plotInfWater(Irrigation_macropiping, "theta"))
dev.off()

##########
# load(file=paste0(dir_output, "Irrigation_combiExt_macropiping_", n_param, ".rdata"))
# plot profile (along x)
# igrav_x = 4564082.00
# igrav_y = 5445669.70
yrel = 8 # [m]
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs60_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 60, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs120_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 120, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs180_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 180, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs240_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 240, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs300_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 300, yrel, "x"))
dev.off()
png(file=paste0(dir_plots, "Distribution_simple_macropiping_ProfileTs360_", n_param, ".png"), width=1000, height=1000, res=250)
plot(plotIrrigationProfile(Irrigation_macropiping, tstep = 360, yrel, "x"))
dev.off()

print(paste0("Saving Irrigation data for n_param: ", n_param))
## save data
save(Irrigation_macropiping, file=paste0(dir_output, "Irrigation_combiExt_macropiping_", n_param, ".rdata"))

# 
##debug
#load data
# load(file=paste0(dir_output, "Irrigation_combiExt_macropiping_", n_param, ".rdata"))
# print(str(Irrigation_macropiping))
# print(str(gcomp_irrigation_domain))
# tt =dplyr::select(Irrigation_macropiping, x,y,z,value,Timestep)
# print(str(tt))
# print(range(tt$Timestep))
# ttt = left_join(gcomp_irrigation_domain, tt)
# print(str(ttt))
# print(range(ttt$Timestep))
# print(range(ttt$value))
# print("other test irrigation dataset:")
# load(file="/home/hydro/mreich/Irrigation/output/combi/Irrigation_simple_macropiping.rdata")
# print("-zgrid")
# tt =dplyr::select(Irrigation_macropiping, -zgrid)
# print(str(tt))
# ttt = left_join(gcomp_irrigation_domain, tt)
# print(str(ttt))
# print("select positiv")
# tt =dplyr::select(Irrigation_macropiping, x,y,z,value,Timestep)
# print(str(tt))
# ttt = left_join(gcomp_irrigation_domain, tt)
# print(str(ttt))

########################################
## gravity response in nm/s²
########################################
## !!
## due to saving into ascii, reading and stiching (within the processing procedure)
## joining columns (x,y,z) have to be rounded! in order to match with gravity component grid
## !!
Irrigation_macropiping$x = round(Irrigation_macropiping$x,2)
Irrigation_macropiping$y = round(Irrigation_macropiping$y,2)
Irrigation_macropiping$z = round(Irrigation_macropiping$z,2)
gcomp_irrigation_domain$x = round(gcomp_irrigation_domain$x,2)
gcomp_irrigation_domain$y = round(gcomp_irrigation_domain$y,2)
gcomp_irrigation_domain$z = round(gcomp_irrigation_domain$z,2)

# should timesteps or POSIXct units be shown on x-axis?
showRealdates = F
# gsignal_irrigation_macropiping = gsignal_grids_3d(gcomp_irrigation_domain, dplyr::select(Irrigation_macropiping, -zgrid), showRealdates)
print("calculating gravity response..")
gsignal_irrigation_macropiping = gsignal_grids_3d(gcomp_irrigation_domain, dplyr::select(Irrigation_macropiping, x,y,z,value,Timestep), showRealdates)
#save gsignal
save(gsignal_irrigation_macropiping, file=paste0(dir_output, "gmod_Irrigation_macropiping_", n_param, ".rdata"))
# print(str(gsignal_irrigation_macropiping))

## combine datasets and plot
gmod = rbind(
         cbind(igrav_timesteps, Scenario="iGrav (observed)"),
	     cbind(gsignal_irrigation_macropiping, Scenario="Macro & Piping")
         )

png(file=paste0(dir_plots, "gmod_signal_Irrigation_combinedExtScenarios_macropipe_", n_param, ".png"), width=1500, height=1000, res=250)
plot(ggplot(gmod, aes(x=Timestep, y=gmod, colour=Scenario)) + geom_line() + 
	ylab("Gravity [nm/s²]") + xlab("Time since irrigation start [min]"))
dev.off()

####################
## calculate fit to gobs

## regular KGE
# kge_value = KGE(gsignal_irrigation_macropiping$gmod, igrav_timesteps$gmod)
## changing scaling factor of component BIAS
kge_value = KGE(gsignal_irrigation_macropiping$gmod, igrav_timesteps$gmod, s=c(2.5/6,2.5/6,1/6))
kge_fit = 1 - kge_value

####################
## clean up memory
rm(Irrigation_macropiping, gsignal_irrigation_macropiping)
gc()
## move to next n_param value for plot indexing
n_param <<- n_param + 1

## returning quality criteria:
## KGE
return(kge_fit) 

## else statement, runs if pipedepth > mdepth
}

print("finished MACROPORES & PIPING !")
####################
} # end of function
