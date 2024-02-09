### This is the MPCC model

## We begin by including the shared sets and parameters.
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

# calorific values on the edge (H_arc)
var CalorificArcVar{(u,v,q) in ARCS} >= CalorificLower, <= CalorificUpper;

# directional flow variable (beta_a)
var DirectionPos{(u,v,q) in ARCS} >=0;

# For flow splitting, HS uses a reformulation with lambda variables and an eta parameter.
# There is a lambda_1 and lambda_2 for each arc and a parameter eta which is chosen to be 10^-6
# Thus, below we define the lambda1 and lambda2 variables for each ARCS
var lambda_1{(u,v,q) in ARCS} >= 0;
var lambda_2{(u,v,q) in ARCS} >= 0;

# Phi
var Phi{(u,v,q) in PIPES};

# change of pressure (delta)
var PressureChangeVar{(u,v,q) in UNI} >= PressureChangeLower[u,v,q], <= PressureChangeUpper[u,v,q];

minimize Z: sum{(u,v,q) in COMPRESSORS} PressureChangeVar[u,v,q];

subject to massbalance{u in NODES}: 
FlowInOut[u] = sum{(u,v,q) in ARCS} FlowArcVar[u,v,q] - sum{(v,u,q) in ARCS} FlowArcVar[v,u,q];

subject to pressurebalance{(u,v,q) in PIPES}: 
-SlackPressure <=
PressureVar[v]**2 - PressureVar[u]**2  + Phi[u,v,q]
<= SlackPressure;

# Our models do not incoporate the physical properties of
# valves and resistors thus we treat them like short pipes.
# short pipes are just connectors so there is no ability for pressure loss
# thus, we set the pressure variables equal to each other across
# all of these network components.
subject to pressurebalance2{(u,v,q) in SHORTPIPES union VALVES union RESISTORS}: 
PressureVar[v] = PressureVar[u];

# Note (10**6) is divided to make sure convert units (m^4/s^4) into Pa (m^4/(s^4*10^(-6))) while #(100000^2) is to change pressure unit Pa from Bar.
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


# This one is the bivariate pressure loss
#subject to pressurelossinpipe{(u,v,q) in PIPES}:
#Phi[u,v,q] = FrictionFactor[u,v,q] * (
#(DirectionPos[u,v,q]/(1000**2))**2 - ( (DirectionPos[u,v,q]-FlowArcVar[u,v,q]) /(1000**2))**2
#)/(100000**2);

# This one is causing infeasibility
#subject to pressurelossinpipe{(u,v,q) in PIPES}:
#Phi[u,v,q] = FrictionFactor[u,v,q] * ( 
#2*DirectionPos[u,v,q] * FlowArcVar[u,v,q]/(1000**4) - (FlowArcVar[u,v,q]/(1000**2))**2
#)/(100000**2);


param a_param{ (u,v,q) in PIPES} = 2 * Epsilon[u,v,q]; 
param b_param{ (u,v,q) in PIPES} = 1 ;
param c_param{ (u,v,q) in PIPES} = b_param[u,v,q] / ( (log(Beta[u,v,q]) + 1)*Epsilon[u,v,q]**2);
param g_param{ (u,v,q) in PIPES} = b_param[u,v,q]*Lambda[u,v,q] / ( 16*pi*Eta*Diameter[u,v,q] - 2*Epsilon[u,v,q]*Lambda[u,v,q]);

subject to pressurelossinpipe_alternateapprox{(u,v,q) in PIPES}:
-SlackPressure <= Phi[u,v,q] - 
FrictionFactor[u,v,q] * 
( 
 (  (DirectionPos[u,v,q]/(1000**2))**2- ((DirectionPos[u,v,q]-FlowArcVar[u,v,q])/(1000**2))**2 
 #+ 2 * ( DirectionPos[u,v,q]/(1000**2)) * ( FlowArcVar[u,v,q]/(1000**2))
 )
 + 
 a_param[u,v,q] * (FlowArcVar[u,v,q])/(1000**2)
  +
  (
  ( 
   b_param[u,v,q]  * (FlowArcVar[u,v,q])/(1000**2)
   )
    /
   (
    c_param[u,v,q] * (( 2*DirectionPos[u,v,q]-FlowArcVar[u,v,q])/(1000**2))
    +g_param[u,v,q]
    )
    )
)/(100000**2) <= SlackPressure;


subject to pressureincompressor{(u,v,q) in COMPRESSORS}: PressureChangeVar[u,v,q] = PressureVar[v] - PressureVar[u];

subject to pressureincontrolvalve{(u,v,q) in CONTROLVALVES}: PressureChangeVar[u,v,q] = PressureVar[u] - PressureVar[v];

subject to exitheatpowerupperbound{u in SINKS}: 
MixCalorificValue[u]*(FlowInOut[u]) <= HeatPowerUpper[u];

subject to exitheatpowerlowerbound{u in SINKS}: 
MixCalorificValue[u]*(FlowInOut[u]) >= HeatPowerLower[u];

subject to ComplementarityOne{(u,v,q) in ARCS}:
DirectionPos[u,v,q] + 10**(-6)-lambda_1[u,v,q]-lambda_2[u,v,q] = 0;

subject to ComplemtarityTwo{(u,v,q) in ARCS}: DirectionPos[u,v,q] - FlowArcVar[u,v,q] >= 0;

subject to ComplemtarityThree{(u,v,q) in ARCS}: lambda_1[u,v,q]*DirectionPos[u,v,q] <= 0;

subject to ComplemtarityFour{(u,v,q) in ARCS}: lambda_2[u,v,q]* (DirectionPos[u,v,q] - FlowArcVar[u,v,q]) <= 0;

subject to mixingnonsource{u in NODES diff SOURCES}: 
-SlackMixingNonSource <=  
  sum{(v,u,q) in ARCS} DirectionPos[v,u,q]*MixCalorificValue[u] 
+ sum{(u,v,q) in ARCS} (DirectionPos[u,v,q] - FlowArcVar[u,v,q])*MixCalorificValue[u] 
- sum{(v,u,q) in ARCS} DirectionPos[v,u,q]*CalorificArcVar[v,u,q] 
- sum{(u,v,q) in ARCS} (DirectionPos[u,v,q] - FlowArcVar[u,v,q])*CalorificArcVar[u,v,q] 
<= SlackMixingNonSource;
 
subject to mixingsourcenode{u in SOURCES}: 
-SlackMixingSource <=
  FlowInOut[u]*MixCalorificValue[u]
+ sum{(v,u,q) in ARCS} DirectionPos[v,u,q]*MixCalorificValue[u] 
+ sum{(u,v,q) in ARCS} (DirectionPos[u,v,q] - FlowArcVar[u,v,q])*MixCalorificValue[u] 
- CalorificValue[u]*FlowInOut[u] 
- sum{(v,u,q) in ARCS} DirectionPos[v,u,q]*CalorificArcVar[v,u,q]
- sum{(u,v,q) in ARCS} (DirectionPos[u,v,q] - FlowArcVar[u,v,q])*CalorificArcVar[u,v,q]
<= SlackMixingSource; 

subject to propagationoutward{(u,v,q) in ARCS}: 
(MixCalorificValue[u] -CalorificArcVar[u,v,q])*(DirectionPos[u,v,q]) = 0;
                                                
subject to propagationinward{(v,u,q) in ARCS}: 
(MixCalorificValue[u] -CalorificArcVar[v,u,q])*(DirectionPos[v,u,q] - FlowArcVar[v,u,q]) = 0;



###############################################################################
###############################################################################
# Linear McCormick Constraints
###############################################################################
###############################################################################
# Can use C style block comments

/*
# Redundant constraint for MPCC
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



subject to McCormickNodeOutBound1 {(u,v,q) in ARCS}: 
    FlowArcVar[u,v,q]*MixCalorificValue[u] >= 
    FlowLowerArc[u,v,q] * MixCalorificValue[u] + FlowArcVar[u,v,q] * CalorificLower 
    - FlowLowerArc[u,v,q]*CalorificLower;

subject to McCormickNodeOutBound2 {(u,v,q) in ARCS}:
    FlowArcVar[u,v,q] * MixCalorificValue[u] >= 
    FlowUpperArc[u,v,q]*MixCalorificValue[u] + FlowArcVar[u,v,q] * CalorificUpper
    - FlowUpperArc[u,v,q]*CalorificUpper;
    
subject to McCormickNodeOutBound3 {(u,v,q) in ARCS}:
    FlowArcVar[u,v,q] * MixCalorificValue[u] <= 
    FlowUpperArc[u,v,q]*MixCalorificValue[u] + FlowArcVar[u,v,q]*CalorificLower
    - FlowUpperArc[u,v,q]*CalorificLower;

subject to McCormickNodeOutBound4 {(u,v,q) in ARCS}:
    FlowArcVar[u,v,q] * MixCalorificValue[u] <= 
    FlowArcVar[u,v,q]*CalorificUpper + FlowLowerArc[u,v,q]*MixCalorificValue[u] 
    - FlowLowerArc[u,v,q]*CalorificUpper;

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


subject to McCormickArcOutBound1 {(u,v,q) in ARCS}: 
    FlowArcVar[u,v,q]*CalorificArcVar[u,v,q] >= 
    FlowLowerArc[u,v,q] * CalorificArcVar[u,v,q] + FlowArcVar[u,v,q] * CalorificLower 
    - FlowLowerArc[u,v,q]*CalorificLower;

subject to McCormickArcOutBound2 {(u,v,q) in ARCS}:
    FlowArcVar[u,v,q] * CalorificArcVar[u,v,q] >= 
    FlowUpperArc[u,v,q]*CalorificArcVar[u,v,q] + FlowArcVar[u,v,q] * CalorificUpper
    - FlowUpperArc[u,v,q]*CalorificUpper;
    
subject to McCormickArcOutBound3 {(u,v,q) in ARCS}:
    FlowArcVar[u,v,q] * CalorificArcVar[u,v,q] <= 
    FlowUpperArc[u,v,q]*CalorificArcVar[u,v,q] + FlowArcVar[u,v,q]*CalorificLower
    - FlowUpperArc[u,v,q]*CalorificLower;

subject to McCormickArcOutBound4 {(u,v,q) in ARCS}:
    FlowArcVar[u,v,q] * CalorificArcVar[u,v,q] <= 
    FlowArcVar[u,v,q]*CalorificUpper + FlowLowerArc[u,v,q]*CalorificArcVar[u,v,q] 
    - FlowLowerArc[u,v,q]*CalorificUpper;
*/
