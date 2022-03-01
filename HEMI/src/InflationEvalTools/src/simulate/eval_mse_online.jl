# eval_mse_online.jl - Generación de MSE de optimización online  

"""
    function eval_mse_online(config::SimConfig, tray_infl_param; 
        K = 1000, rnsdeed = DEFAULT_SEED) -> mse

Función para obtener evaluación de error cuadrático medio utilizando
configuración de evaluación [`SimConfig`](@ref). Se debe proveer la trayectoria
paramétrica de comparación en `tray_infl_param`, esto para evitar su cómputo
repetido en esta función. Devuelve el MSE como un escalar.

Esta función se puede utilizar para optimizar los parámetros de diferentes
medidas de inflación y es más eficiente en memoria que [`pargentrayinfl`](@ref). 
"""
function eval_mse_online(config::SimConfig, csdata::CountryStructure, tray_infl_param; 
    K = 1000, rnsdeed = DEFAULT_SEED)
    # Desempaquetar la configuración 
    eval_mse_online(config.inflfn, config.resamplefn, config.trendfn, csdata, tray_infl_param; K)
end


"""
    function eval_mse_online(inflfn::InflationFunction,
        resamplefn::ResampleFunction, trendfn::TrendFunction,
        csdata::CountryStructure, tray_infl_param; K = 100, rndseed = DEFAULT_SEED) -> mse

Función para obtener evaluación de error cuadrático medio (MSE) utilizando las
funciones especificadas. Devuelve el MSE como un escalar.
"""
function eval_mse_online(inflfn::InflationFunction,
    resamplefn::ResampleFunction, trendfn::TrendFunction,
    csdata::CountryStructure, tray_infl_param; K = 100, rndseed = DEFAULT_SEED)

    # Tarea de cómputo de trayectorias
    mse = @showprogress @distributed (OnlineStats.merge) for k in 1:K 
        # Configurar la semilla en el proceso
        Random.seed!(LOCAL_RNG, rndseed + k)

        # Muestra de bootstrap de los datos 
        bootsample = resamplefn(csdata, LOCAL_RNG)
        # Aplicación de la función de tendencia 
        trended_sample = trendfn(bootsample)

        # Computar la medida de inflación y el MSE
        tray_infl = inflfn(trended_sample)
        sq_err = (tray_infl - tray_infl_param) .^ 2
        o = OnlineStats.Mean(eltype(csdata))
        OnlineStats.fit!(o, sq_err)
    end 

    OnlineStats.value(mse)::eltype(csdata)
end
