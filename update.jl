## Importando Paquetes -----------------------------------------------
using DrWatson
using Pkg
using DataFrames, CSV

source_dir = Base.source_dir()

hemi_path = joinpath(source_dir,"HEMI")
Pkg.activate(hemi_path)

using HEMI 
using StringEncodings



## Actualización de Datos ---------------------------------------------
@info "Actualizando archivo de datos"
include(scriptsdir("load_data.jl"))
HEMI.load_data()


## Functiones Auxiliares ------------------------------------------------

include(scriptsdir("updates_helpers.jl"))


## Construccion de Medidas Optimas 2022 ------------------------------------

include(joinpath(Base.source_dir(),"2022","optmse2022.jl"))

include(joinpath(Base.source_dir(),"2022","optabsme2022.jl"))

include(joinpath(Base.source_dir(),"2022","optcorr2022.jl"))

## Construccion de Medidas Optimas 2021 ------------------------------------

include(joinpath(Base.source_dir(),"2021","optmse2021.jl"))

include(joinpath(Base.source_dir(),"2021","optabsme2021.jl"))

include(joinpath(Base.source_dir(),"2021","optcorr2021.jl"))

## Fechas ------------------------------------------------------------------

dates     = infl_dates(gtdata) |> x->Dates.format.(x,"01/mm/yyyy")
idx_dates = (infl_dates(gtdata)[1] - Month(11): Month(1) : infl_dates(gtdata)[end]) |> x->Dates.format.(x,"01/mm/yyyy")

## DATAFRAMES 2021 ---------------------------------------------------------------------

# MSE_optimization
MSE_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optmse2021(gtdata, CPIIndex()),
    "Combinación lineal óptima MSE" =>  vcat(fill(NaN, 11), optmse2021(gtdata))
)

# ABSME_optimization
ABSME_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optabsme2021(gtdata, CPIIndex()),
    "Combinación lineal óptima ABSME" =>  vcat(fill(NaN, 11), optabsme2021(gtdata))
)

# CORR_optimization
CORR_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optcorr2021(gtdata, CPIIndex()),
    "Combinación lineal óptima CORR" =>  vcat(fill(NaN, 11), optcorr2021(gtdata))
)

#MSE_optimization_interannual_components
opt_components = components(optmse2021)
mai_components = components(optmai_mse2021)
df1 = DataFrame(optmse2022.ensemble(gtdata), opt_components.measure)
df2 = DataFrame(optmai_mse2021.ensemble(gtdata), mai_components.measure)
MSE_optimization_interannual_components = hcat(df1, df2)
insertcols!(MSE_optimization_interannual_components, 1, "Fecha" => dates)

#ABSME_optimization_interannual_components
opt_components = components(optabsme2021)
mai_components = components(optmai_absme2021)
df1 = DataFrame(optabsme2022.ensemble(gtdata), opt_components.measure)
df2 = DataFrame(optmai_absme2021.ensemble(gtdata), mai_components.measure)
ABSME_optimization_interannual_components = hcat(df1, df2)
insertcols!(ABSME_optimization_interannual_components, 1, "Fecha" => dates)

#CORR_optimization_interannual_components
opt_components = components(optcorr2021)  #Para orden correcto
mai_components = components(optmai_corr2021)
df1 = DataFrame(optcorr2022.ensemble(gtdata), opt_components.measure)
df2 = DataFrame(optmai_corr2021.ensemble(gtdata), mai_components.measure)
CORR_optimization_interannual_components = hcat(df1, df2)
insertcols!(CORR_optimization_interannual_components, 1, "Fecha" => dates)

## CSVs 2021 ----------------------------------------------------------------------------

csv_savepath = joinpath(Base.source_dir(),"CSVs","HEMI2021")

save_csv(joinpath(csv_savepath, "MSE_optimization.csv"), MSE_optimization)
save_csv(joinpath(csv_savepath, "ABSME_optimization.csv"), ABSME_optimization)
save_csv(joinpath(csv_savepath, "CORR_optimization.csv"), CORR_optimization)

save_csv(joinpath(csv_savepath, "MSE_optimization_interannual_components.csv"), MSE_optimization_interannual_components)
save_csv(joinpath(csv_savepath, "ABSME_optimization_interannual_components.csv"), ABSME_optimization_interannual_components)
save_csv(joinpath(csv_savepath, "CORR_optimization_interannual_components.csv"), CORR_optimization_interannual_components)


## DATAFRAMES  MENSUALES 2022  ---------------------------------------------------------------

# MSE_confidence_intervals

dates_ci = infl_dates(gtdata)
inf_limit = Vector{Union{Missing, Float32}}(undef, length(dates_ci))
sup_limit = Vector{Union{Missing, Float32}}(undef, length(dates_ci))
opt_obs = optmse2022(gtdata)


for t in 1:length(dates)
    for r in eachrow(optmse2022_ci)
        period = r.evalperiod
        if period.startdate <= dates_ci[t] <= period.finaldate
            inf_limit[t] = opt_obs[t] + r.inf_limit
            sup_limit[t] = opt_obs[t] + r.sup_limit
        end
    end
end

MSE_confidence_intervals = DataFrame(
    "Fecha" => dates,
    "OPT_MSE" => opt_obs,
    "LIM_INF" => inf_limit,
    "LIM_SUP" => sup_limit
)


# MSE_optimization
MSE_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optmse2022(gtdata, CPIIndex()),
    "Combinación lineal óptima MSE" =>  vcat(fill(NaN, 11), optmse2022(gtdata))
)

# ABSME_optimization
ABSME_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optabsme2022(gtdata, CPIIndex()),
    "Combinación lineal óptima ABSME" =>  vcat(fill(NaN, 11), optabsme2022(gtdata))
)

# CORR_optimization
CORR_optimization = DataFrame(
    "Fecha"  => idx_dates,
    "Índice" => optcorr2022(gtdata, CPIIndex()),
    "Combinación lineal óptima CORR" =>  vcat(fill(NaN, 11), optcorr2022(gtdata))
)

#MSE_optimization_index_components
opt_components = components(optmse2022)
mai_components = components(optmai2018)
df1 = DataFrame(optmse2022.ensemble(gtdata, CPIIndex()), opt_components.measure)
df2 = DataFrame(optmai2018.ensemble(gtdata, CPIIndex()), mai_components.measure)
MSE_optimization_index_components = hcat(df1, df2)
insertcols!(MSE_optimization_index_components, 1, "Fecha" => idx_dates)

#ABSME_optimization_index_components
opt_components = components(optabsme2022)
mai_components = components(optmai2018_absme)
df1 = DataFrame(optabsme2022.ensemble(gtdata, CPIIndex()), opt_components.measure)
df2 = DataFrame(optmai2018_absme.ensemble(gtdata, CPIIndex()), mai_components.measure)
ABSME_optimization_index_components = hcat(df1, df2)
insertcols!(ABSME_optimization_index_components, 1, "Fecha" => idx_dates)

#CORR_optimization_index_components
opt_components = components(optcorr2022)  
mai_components = components(optmai2018_corr)
df1 = DataFrame(optcorr2022.ensemble(gtdata, CPIIndex()), opt_components.measure)
df2 = DataFrame(optmai2018_corr.ensemble(gtdata, CPIIndex()), mai_components.measure)
CORR_optimization_index_components = hcat(df1, df2)
insertcols!(CORR_optimization_index_components, 1, "Fecha" => idx_dates)

#MSE_optimization_interannual_components
opt_components = components(optmse2022)
mai_components = components(optmai2018)
df1 = DataFrame(optmse2022.ensemble(gtdata), opt_components.measure)
df2 = DataFrame(optmai2018.ensemble(gtdata), mai_components.measure)
MSE_optimization_interannual_components = hcat(df1, df2)
insertcols!(MSE_optimization_interannual_components, 1, "Fecha" => dates)

#ABSME_optimization_interannual_components
opt_components = components(optabsme2022)
mai_components = components(optmai2018_absme)
df1 = DataFrame(optabsme2022.ensemble(gtdata), opt_components.measure)
df2 = DataFrame(optmai2018_absme.ensemble(gtdata), mai_components.measure)
ABSME_optimization_interannual_components = hcat(df1, df2)
insertcols!(ABSME_optimization_interannual_components, 1, "Fecha" => dates)

#CORR_optimization_interannual_components
opt_components = components(optcorr2022)  #Para orden correcto
mai_components = components(optmai2018_corr)
df1 = DataFrame(optcorr2022.ensemble(gtdata), opt_components.measure)
df2 = DataFrame(optmai2018_corr.ensemble(gtdata), mai_components.measure)
CORR_optimization_interannual_components = hcat(df1, df2)
insertcols!(CORR_optimization_interannual_components, 1, "Fecha" => dates)

## CSVs mensuales ----------------------------------------------------------------

csv_savepath = joinpath(Base.source_dir(),"CSVs")

save_csv(joinpath(csv_savepath, "MSE_confidence_intervals.csv"), MSE_confidence_intervals)

save_csv(joinpath(csv_savepath, "MSE_optimization.csv"), MSE_optimization)
save_csv(joinpath(csv_savepath, "ABSME_optimization.csv"), ABSME_optimization)
save_csv(joinpath(csv_savepath, "CORR_optimization.csv"), CORR_optimization)

save_csv(joinpath(csv_savepath, "MSE_optimization_index_components.csv"), MSE_optimization_index_components)
save_csv(joinpath(csv_savepath, "ABSME_optimization_index_components.csv"), ABSME_optimization_index_components)
save_csv(joinpath(csv_savepath, "CORR_optimization_index_components.csv"), CORR_optimization_index_components)

save_csv(joinpath(csv_savepath, "MSE_optimization_interannual_components.csv"), MSE_optimization_interannual_components)
save_csv(joinpath(csv_savepath, "ABSME_optimization_interannual_components.csv"), ABSME_optimization_interannual_components)
save_csv(joinpath(csv_savepath, "CORR_optimization_interannual_components.csv"), CORR_optimization_interannual_components)



## DATAFRAMES ANUALES -----------------------------------------------------------------

# NO ES NECESARIO POR EL MOMENTO. ACTIVAR EN CASO DE NO TENER LOS ARCHIVOS
#=

# MSE_optimization_final_weights
temp1 = components(optmse2022).weights
temp2 = components(optmse2022).measure
temp1 = reshape(temp1, (1,7))
MSE_optimization_final_weights = DataFrame(temp1,temp2)

# ABSME_optimization_final_weights
temp1 = components(optabsme2022).weights
temp2 = components(optabsme2022).measure
temp1 = reshape(temp1, (1,7))
ABSME_optimization_final_weights = DataFrame(temp1,temp2)

# CORR_optimization_final_weights
temp1 = components(optcorr2022).weights 
temp2 = components(optcorr2022).measure 
temp1 = reshape(temp1, (1,7))
CORR_optimization_final_weights = DataFrame(temp1,temp2)

# MSE_optimization_mai_weights
temp1 = components(optmai2018).weights
temp2 = components(optmai2018).measure
temp1 = reshape(temp1, (1,3))
MSE_optimization_mai_weights = DataFrame(temp1,temp2)

# ABSME_optimization_mai_weights
temp1 = components(optmai2018_absme).weights
temp2 = components(optmai2018_absme).measure
temp1 = reshape(temp1, (1,3))
ABSME_optimization_mai_weights = DataFrame(temp1,temp2)

# CORR_optimization_mai_weights
temp1 = components(optmai2018_corr).weights
temp2 = components(optmai2018_corr).measure
temp1 = reshape(temp1, (1,3))
CORR_optimization_mai_weights = DataFrame(temp1,temp2)

## CSVs Anuales ----------------------------------------------------------------

save_csv(joinpath(csv_savepath, "MSE_optimization_final_weights.csv"), MSE_optimization_final_weights)
save_csv(joinpath(csv_savepath, "ABSME_optimization_final_weights.csv"), ABSME_optimization_final_weights)
save_csv(joinpath(csv_savepath, "CORR_optimization_final_weights.csv"), CORR_optimization_final_weights)

save_csv(joinpath(csv_savepath, "MSE_optimization_mai_weights.csv"), MSE_optimization_mai_weights)
save_csv(joinpath(csv_savepath, "ABSME_optimization_mai_weights.csv"), ABSME_optimization_mai_weights)
save_csv(joinpath(csv_savepath, "CORR_optimization_mai_weights.csv"), CORR_optimization_mai_weights)
 
=#

## EVALUACIONES ANUALES ----------------------------------------------------------------------------

# Queda pendiente esta parte




