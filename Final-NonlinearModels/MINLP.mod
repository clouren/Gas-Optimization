### This is the MINLP model, which is the second model presented in the paper
### The model utilizes the same idea as the NLP but smooths the pressure loss
### and does not have any variable sets


## We begin by including the shared sets and parameters.
## The user should uncomment which one is appropriate for specific location
## For the cluster, we only need the following:
#include "shared-data.txt"

## For a local run, one needs to give the full path to the file. For example
## on Chris macbook it is:
include "/Users/chris-macbook/Google Drive/My Drive/Geonhee-Gas Networks/Code/Updated AMPL Model Files-June 2023/shared-data.txt"

# Variables

# Node Variables

# pressure (p)
var PressureVar{u in NODES} >= PressureLower[u], <= PressureUpper[u];

# mixing calorific value (H_node)
var MixCalorificValue{u in NODES} >=CalorificLower, <=CalorificUpper;

# Arc Variables

# arc flow (q)
var FlowArcVar{(u,v,q) in ARCS} >= FlowLowerArc[u,v,q], <= FlowUpperArc[u,v,q];

# calorific values on the edge 
var CalorificArcVar{(u,v,q) in ARCS} >=CalorificLower, <= CalorificUpper;

# direction of flow variable
var Direction{(u,v,q) in ARCS} binary;

# directional flow variable (beta_a)
var DirectionPos{(u,v,q) in ARCS} >=0;

# directional flow variable (gamma_a)
var DirectionNeg{(u,v,q) in ARCS} >=0;

# Phi
var Phi{(u,v,q) in PIPES};

# change of pressure (delta)
var PressureChangeVar{(u,v,q) in UNI} >=PressureChangeLower[u,v,q], <= PressureChangeUpper[u,v,q];

minimize Z: sum{(u,v,q) in COMPRESSORS} PressureChangeVar[u,v,q];

subject to massbalance{u in NODES}: 
FlowInOut[u] = sum{(u,v,q) in ARCS} FlowArcVar[u,v,q] - sum{(v,u,q) in ARCS} FlowArcVar[v,u,q];


# Note (10**6) is divided to make sure convert units (m^4/s^4) into Pa (m^4/(s^4*10^(-6))) while (100000^2) is to change pressure unit Pa from Bar.
subject to pressurelossinpipe{(u,v,q) in PIPES}: 
Phi[u,v,q] = FrictionFactor[u,v,q]*
(
    (
        sqrt(FlowArcVar[u,v,q]**2 + e[u,v,q]**2)
        /(1000**2)
        + b[u,v,q]
        + (c[u,v,q]/sqrt(FlowArcVar[u,v,q]**2 + d[u,v,q]**2))/(1000**2)
    )*(FlowArcVar[u,v,q]/(1000**2))
)/(100000**2);

subject to pressurebalance{(u,v,q) in PIPES}: 
-SlackPressure <=
PressureVar[v]**2 - PressureVar[u]**2  + Phi[u,v,q]
<= SlackPressure;

subject to pressureincompresser{(u,v,q) in COMPRESSORS}: PressureChangeVar[u,v,q] = PressureVar[v] - PressureVar[u];

subject to pressureincontrolvavle{(u,v,q) in CONTROLVALVES}: PressureChangeVar[u,v,q] = PressureVar[u] - PressureVar[v];

subject to exitheatpowerupperbound{u in SINKS}: MixCalorificValue[u]*FlowInOut[u] <= HeatPowerUpper[u];
subject to exitheatpowerlowerbound{u in SINKS}: MixCalorificValue[u]*FlowInOut[u] >= HeatPowerLower[u];

subject to Flowsplittingone{(u,v,q) in ARCS}: FlowArcVar[u,v,q] = DirectionPos[u,v,q] - DirectionNeg[u,v,q];

subject to Flowsplittingtwo{(u,v,q) in ARCS}: DirectionNeg[u,v,q] <= (Direction[u,v,q]-1)*FlowLowerArc[u,v,q];

subject to Flowsplittingthree{(u,v,q) in ARCS}: DirectionPos[u,v,q] <= Direction[u,v,q]*FlowUpperArc[u,v,q];

subject to mixingnonsource{u in NODES diff SOURCES}:   
       -SlackMixingNonSource <= 
       -(
            ((sum{ (v,u,q) in ARCS} DirectionPos[v,u,q]) +
            ( sum{ (u,v,q) in ARCS} DirectionNeg[u,v,q])) 
            * MixCalorificValue[u]
        ) + 
        (
            sum{ (v,u,q) in ARCS} DirectionPos[v,u,q]*CalorificArcVar[v,u,q]
        ) 
        + 
        (
            sum{ (u,v,q) in ARCS}( DirectionNeg[u,v,q]*CalorificArcVar[u,v,q])
        ) 
        <= SlackMixingNonSource ;

subject to mixingsourcenode{u in SOURCES}: 
            - SlackMixingSource <=
            -(
                (FlowInOut[u] + (sum{(v,u,q) in ARCS} DirectionPos[v,u,q]) + 
                ( sum{ (u,v,q) in ARCS} DirectionNeg[u,v,q])) 
                * MixCalorificValue[u]
            ) + 
            CalorificValue[u]*FlowInOut[u] + 
            (
                sum{(v,u,q) in ARCS}( DirectionPos[v,u,q]*CalorificArcVar[v,u,q])
            ) + 
            (
                sum{ (u,v,q) in ARCS} (DirectionNeg[u,v,q]* CalorificArcVar[u,v,q])
            ) 
            <= SlackMixingSource;

subject to propagationoutwardupper{(u,v,q) in ARCS}: 
        (MixCalorificValue[u] -CalorificArcVar[u,v,q])
        <= (CalorificUpper - CalorificLower)*(1-Direction[u,v,q]);
                        
subject to propagationoutwardlower{(u,v,q) in ARCS}: 
        (MixCalorificValue[u] -CalorificArcVar[u,v,q])
        >= -(CalorificUpper - CalorificLower)*(1-Direction[u,v,q]);
                        
subject to propagationinwardupper{(v,u,q) in ARCS}: 
        (MixCalorificValue[u] -CalorificArcVar[v,u,q]) 
        <= (CalorificUpper - CalorificLower)*Direction[v,u,q];
                        
subject to propagationinwardlower{(v,u,q) in ARCS}: 
        (MixCalorificValue[u] -CalorificArcVar[v,u,q])
        >= -(CalorificUpper - CalorificLower)*Direction[v,u,q];
                       
