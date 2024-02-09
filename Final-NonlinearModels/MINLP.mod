### This is the MINLP model


## We begin by including the shared sets and parameters.
## If this does not work, give the full path to the file.
include "./shared-data.txt"


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

## Square Root Pressure Loss Approximation
# Note (10**6) is divided to make sure convert units (m^4/s^4) into Pa (m^4/(s^4*10^(-6))) while (100000^2) is to change pressure unit Pa from Bar.
#subject to pressurelossinpipe{(u,v,q) in PIPES}: 
#Phi[u,v,q] = FrictionFactor[u,v,q]*
#(
#    (
#        sqrt(FlowArcVar[u,v,q]**2 + e[u,v,q]**2)
#        /(1000**2)
#        + b[u,v,q]
#        + (c[u,v,q]/sqrt(FlowArcVar[u,v,q]**2 + d[u,v,q]**2))/(1000**2)
#    )*(FlowArcVar[u,v,q]/(1000**2))
#)/(100000**2);


## Univariate Pressure Loss Reformulation
subject to pressurelossinpipe{(u,v,q) in PIPES}:
Phi[u,v,q] = FrictionFactor[u,v,q] * (
(DirectionPos[u,v,q]/(1000**2))**2 - (DirectionNeg[u,v,q]/(1000**2))**2
)/(100000**2);

# Alternate approximation of pressure loss using the beta gamma variables
# and no square root. Currently is equation E.1 in paper.
# To begin with, define a few helper parameters

/*
param a_param{ (u,v,q) in PIPES} = 2 * Epsilon[u,v,q]; 
param b_param{ (u,v,q) in PIPES} = 0.001 ;
param c_param{ (u,v,q) in PIPES} = b_param[u,v,q] / ( (log(Beta[u,v,q]) + 1)*Epsilon[u,v,q]**2);
param g_param{ (u,v,q) in PIPES} = b_param[u,v,q]*Lambda[u,v,q] / ( 16*pi*Eta*Diameter[u,v,q] - 2*Epsilon[u,v,q]*Lambda[u,v,q]);

param b_over_c{ (u,v,q) in PIPES} = b_param[u,v,q] / c_param[u,v,q];
param b_over_g{ (u,v,q) in PIPES} = b_param[u,v,q] / g_param[u,v,q];

subject to pressurelossinpipe_alternateapprox{(u,v,q) in PIPES}:
-SlackPressure <= Phi[u,v,q] - 
FrictionFactor[u,v,q] * 
( 
 (  (DirectionPos[u,v,q]+ DirectionNeg[u,v,q])/(1000**2) * (DirectionPos[u,v,q]-DirectionNeg[u,v,q])/(1000**2))
 + 
 a_param[u,v,q] * (DirectionPos[u,v,q]-DirectionNeg[u,v,q])/(1000**2)
  +
  (
  ( 
   b_param[u,v,q]  * (DirectionPos[u,v,q]-DirectionNeg[u,v,q])/(1000**2)
   )
    /
   (
    c_param[u,v,q] * (( DirectionPos[u,v,q]+DirectionNeg[u,v,q])/(1000**2))
    +g_param[u,v,q]
    )
    )
)/(100000**2) <= SlackPressure;
*/

# Alternate approximation of pressure loss using the beta gamma variables but not having
# a fraction. This is currently equations E.5 and E.6 from the paper

# New variable epsilon
#var PL_Epsilon{(u,v,q) in PIPES};

#subject to pressurelossinpipe_alternateapprox_nofrac{(u,v,q) in PIPES}:
#-SlackPressure <=
#Phi[u,v,q] - FrictionFactor[u,v,q] * 
#( 
#    (DirectionPos[u,v,q]/(1000**2))**2 - (DirectionNeg[u,v,q]/(1000**2))**2
#    + a_param[u,v,q] * ( (DirectionPos[u,v,q]-DirectionNeg[u,v,q])/(1000**2)) 
#    + PL_Epsilon[u,v,q]
#)/(100000**2)
#<= SlackPressure;


#subject to EpsilonDefConstraint{(u,v,q) in PIPES}:
#-SlackPressure <= 
#b_param[u,v,q]*(DirectionPos[u,v,q]-DirectionNeg[u,v,q])/(1000**2)
#- c_param[u,v,q] * (DirectionPos[u,v,q]/(1000**2) * PL_Epsilon[u,v,q] + 
#            DirectionNeg[u,v,q]/(1000**2)*PL_Epsilon[u,v,q]) - 
#            g_param[u,v,q]*PL_Epsilon[u,v,q] 
#    <= SlackPressure;
   
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

###############################################################################
###############################################################################
# Linear McCormick Constraints
###############################################################################
###############################################################################
# Can use C style block comments

/*
# Redundant constraint for MINLP
#subject to McCormickNodeInBound1 {(v,u,q) in ARCS}: 
#    DirectionPos[v,u,q]*MixCalorificValue[u]  >=  DirectionPos[v,u,q]*CalorificLower;

subject to McCormickNodeInBound2 {(v,u,q) in ARCS}:
    DirectionPos[v,u,q]*MixCalorificValue[u] >= 
    FlowUpperArc[v,u,q]*MixCalorificValue[u]+DirectionPos[v,u,q]*CalorificUpper - FlowUpperArc[v,u,q]*CalorificUpper ;
    
subject to McCormickNodeInBound3 {(v,u,q) in ARCS}:
    DirectionPos[v,u,q]*MixCalorificValue[u] <=
    FlowUpperArc[v,u,q] * MixCalorificValue[u] + DirectionPos[v,u,q] * CalorificLower - FlowUpperArc[v,u,q]*CalorificLower;

# Redundant constraint for MINLP
#subject to McCormickNodeInBound4 {(v,u,q) in ARCS}:
#    DirectionPos[v,u,q]*MixCalorificValue[u] <=
#    DirectionPos[v,u,q]*CalorificUpper;


# Redundant constraint for MINLP
#subject to McCormickNodeOutBound1 {(u,v,q) in ARCS}: 
#    DirectionNeg[u,v,q]*MixCalorificValue[u] >= 
#    DirectionNeg[u,v,q]*CalorificLower;

subject to McCormickNodeOutBound2 {(u,v,q) in ARCS}:
    DirectionNeg[u,v,q]*MixCalorificValue[u] >= 
    abs(FlowLowerArc[u,v,q])*MixCalorificValue[u]+DirectionNeg[u,v,q]*CalorificUpper - abs(FlowLowerArc[u,v,q])*CalorificUpper;
    
subject to McCormickNodeOutBound3 {(u,v,q) in ARCS}:
    DirectionNeg[u,v,q]*MixCalorificValue[u] <=
    abs(FlowLowerArc[u,v,q]) * MixCalorificValue[u] + DirectionNeg[u,v,q] * CalorificLower - abs(FlowLowerArc[u,v,q])*CalorificLower;

# Redundant constraint for MINLP
#subject to McCormickNodeOutBound4 {(u,v,q) in ARCS}:
#    DirectionNeg[u,v,q]*MixCalorificValue[u] <=
#    DirectionNeg[u,v,q]*CalorificUpper;

# Redundant constraint for MINLP
#subject to McCormickArcInBound1 {(v,u,q) in ARCS}: 
#    DirectionPos[v,u,q]*CalorificArcVar[v,u,q] >= 
#    DirectionPos[v,u,q]*CalorificLower;

subject to McCormickArcInBound2 {(v,u,q) in ARCS}:
    DirectionPos[v,u,q]*CalorificArcVar[v,u,q] >= 
    FlowUpperArc[v,u,q]*CalorificArcVar[v,u,q]+DirectionPos[v,u,q]*CalorificUpper - FlowUpperArc[v,u,q]*CalorificUpper;
    
subject to McCormickArcInBound3 {(v,u,q) in ARCS}:
    DirectionPos[v,u,q]*CalorificArcVar[v,u,q] <=
    FlowUpperArc[v,u,q] * CalorificArcVar[v,u,q] + DirectionPos[v,u,q] * CalorificLower - FlowUpperArc[v,u,q]*CalorificLower;

# Redundant constraint for MINLP
#subject to McCormickArcInBound4 {(v,u,q) in ARCS}:
#    DirectionPos[v,u,q]*CalorificArcVar[v,u,q] <=
#    DirectionPos[v,u,q]*CalorificUpper;

# Redundant constraint for MINLP
#subject to McCormickArcOutBound1 {(u,v,q) in ARCS}: 
#    DirectionNeg[u,v,q]*CalorificArcVar[u,v,q] >= 
#    DirectionNeg[u,v,q]*CalorificLower;

subject to McCormickArcOutBound2 {(u,v,q) in ARCS}:
    DirectionNeg[u,v,q]*CalorificArcVar[u,v,q] >= 
    abs(FlowLowerArc[u,v,q])*CalorificArcVar[u,v,q]+DirectionNeg[u,v,q]*CalorificUpper - abs(FlowLowerArc[u,v,q])*CalorificUpper;
    
subject to McCormickArcOutBound3 {(u,v,q) in ARCS}:
    DirectionNeg[u,v,q]*CalorificArcVar[u,v,q] <=
    abs(FlowLowerArc[u,v,q]) * CalorificArcVar[u,v,q] + DirectionNeg[u,v,q] * CalorificLower - abs(FlowLowerArc[u,v,q])*CalorificLower;

# Redundant constraint for MINLP
#subject to McCormickArcOutBound4 {(u,v,q) in ARCS}:
#    DirectionNeg[u,v,q]*CalorificArcVar[u,v,q] <=
#    DirectionNeg[u,v,q]*CalorificUpper;


###############################################################################
###############################################################################
# Bounds using d variables
###############################################################################
###############################################################################

# most simple bounds are the term Buv H = 0 if duv = 0 and yuv H = 0 if duv = 1
# this can be achieved with the following four constraints


subject to SimpleDUpperBound1{(v,u,q) in ARCS}:
DirectionPos[v,u,q] * MixCalorificValue[u] <= Direction[v,u,q] * FlowUpperArc[v,u,q]*CalorificUpper;

subject to SimpleDUpperBound2{(v,u,q) in ARCS}:
DirectionPos[v,u,q] * CalorificArcVar[v,u,q] <= Direction[v,u,q] * FlowUpperArc[v,u,q]*CalorificUpper;

subject to SimpleDUpperBound3{(u,v,q) in ARCS}:
DirectionNeg[u,v,q] * MixCalorificValue[u] <= (1-Direction[u,v,q])* abs(FlowLowerArc[u,v,q]) * CalorificUpper;

subject to SimpleDUpperBound4{(u,v,q) in ARCS}:
DirectionNeg[u,v,q] * CalorificArcVar[u,v,q] <= (1-Direction[u,v,q])* abs(FlowLowerArc[u,v,q]) * CalorificUpper;
*/

###############################################################################
###############################################################################
# Flow cuts using d
###############################################################################
###############################################################################

# At internal nodes if there is flow in there must be flow flow out 

param Degree{u in NODES}:= sum{(u,v,q) in ARCS} 1 + sum{(v,u,q) in ARCS} 1;

subject to FlowInNodes1{(v,u,q) in ARCS: u in NODES diff (SOURCES union SINKS) and Degree[u] >1}:
(sum{ (u,w,z) in ARCS} Direction[u,w,z]) + ( sum { (w,u,z) in ARCS diff {(v,u,q)} } (1 - Direction[w,u,z])  ) >= Direction[v,u,q];

subject to FlowInNodes2{(u,v,q) in ARCS: u in NODES diff (SOURCES union SINKS) and Degree[u] >1}:
( sum { (u,w,z) in ARCS diff {(u,v,q)} } Direction[u,w,z]  )  + (sum{ (w,u,z) in ARCS} (1-Direction[w,u,z]) )  >= 1-Direction[u,v,q];

# At internal nodes if there is flow out there must be flow in

subject to FlowInNodes3{(u,v,q) in ARCS: u in NODES diff (SOURCES union SINKS) and Degree[u] >1}:
(sum{ (w,u,z) in ARCS} Direction[w,u,z]) + ( sum { (u,w,z) in ARCS diff {(u,v,q)} } (1 - Direction[u,w,z])  ) >= Direction[u,v,q];

subject to FlowInNodes4{(v,u,q) in ARCS: u in NODES diff (SOURCES union SINKS) and Degree[u] >1}:
( sum { (w,u,z) in ARCS diff {(v,u,q)} } Direction[w,u,z]  )  + (sum{ (u,w,z) in ARCS} (1-Direction[u,w,z]) )  >= 1-Direction[v,u,q];

# There must be flow out of an entry node
subject to FlowEntryNodes{u in SOURCES}:
sum{ (u,v,q) in ARCS} Direction[u,v,q] + ( sum{ (v,u,q) in ARCS} (1 - Direction[v,u,q])) >= 1;

# There must be flow out of an exit node
subject to FlowExitNodes{u in SINKS}:
sum{ (v,u,q) in ARCS} Direction[v,u,q] + ( sum{ (u,v,q) in ARCS} (1 - Direction[u,v,q])) >= 1;




