### Nonlinear univariate model. All nonlinearities in this model
### arise from quadratic terms x^2. This is achieved by reformulating
### the mixing constraints via a univariate reformulation. Furthermore
### the pressure loss models are reformulated using the positive
### and negative flow variables instead of the absolute value of
### q. This makes the pressure loss smooth however has the downside
### that the derivative does not match at zero.

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

# calorific values on the edge ## It is same as calorific val for node? (H_arc)
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

## New variables for the univariate reformulation.
## The mixing constraints in their nonlinear form have
## a multiplication of flow and calorific variables.
## The univariate approach replaces each bilinear term with an
## exact difference of squares. We will be using Bin 2 from
## the Barmaan paper.
## Thus, for each bilinear term, we have two new variables defined
## leading to a total of 8 new variables which we define below.
## These variables are further approximated by a piecewise linear approximation.
## Bounds are based on the lower and upper bounds of the flow and calorific values
## derived in the paper.

# p1vu in from the paper
var UnivariateNodeIn1{(v,u,q) in ARCS} <= 1/2 * (FlowUpperArc[v,u,q] + CalorificUpper), >= 1/2 * CalorificLower;

#p2uv in from the paper
var UnivariateNodeIn2{(v,u,q) in ARCS} <= 1/2 * (FlowUpperArc[v,u,q] - CalorificLower), >= -1/2 * CalorificUpper ;

#p1uv out from the paper
var UnivariateNodeOut1{(u,v,q) in ARCS} <= 1/2 * (abs(FlowLowerArc[u,v,q]) + CalorificUpper), >= 1/2 * CalorificLower;

#p2uv out from the paper
var UnivariateNodeOut2{(u,v,q) in ARCS} <= 1/2 * (abs(FlowLowerArc[u,v,q]) - CalorificLower), >= -1/2 * CalorificUpper;

#y1uv in from the paper
var UnivariateArcIn1{(u,v,q) in ARCS} <= 1/2 * (FlowUpperArc[u,v,q] + CalorificUpper), >= 1/2 * CalorificLower;

#y2uv in from the paper
var UnivariateArcIn2{(u,v,q) in ARCS} <= 1/2 * (FlowUpperArc[u,v,q] - CalorificLower), >= -1/2 * CalorificUpper;

#y1uv out from the paper
var UnivariateArcOut1{(u,v,q) in ARCS} <= 1/2 * (abs(FlowLowerArc[u,v,q]) + CalorificUpper), >= 1/2 * CalorificLower;

#y2uv out from the paper
var UnivariateArcOut2{(u,v,q) in ARCS} <= 1/2 * (abs(FlowLowerArc[u,v,q]) - CalorificLower), >= -1/2 * CalorificUpper;

param SlackUnivariateDefinition = 0.01;

minimize Z: sum{(u,v,q) in COMPRESSORS} PressureChangeVar[u,v,q];

## We define the equations for each of the new variables

# p1uv in from the paper
subject to UnivariateNodeIn1Definition{(v,u,q) in ARCS}:
-SlackUnivariateDefinition <=
UnivariateNodeIn1[v,u,q] - 1/2 * (DirectionPos[v,u,q] + MixCalorificValue[u])
<= SlackUnivariateDefinition;

#p2uv in from the paper
subject to UnivariateNodeIn2Definition{(v,u,q) in ARCS}:
-SlackUnivariateDefinition <=
UnivariateNodeIn2[v,u,q] - 1/2 * (DirectionPos[v,u,q] - MixCalorificValue[u])
<=SlackUnivariateDefinition;

#p1uv out from the paper
subject to UnivariateNodeOut1Definition{(u,v,q) in ARCS}:
-SlackUnivariateDefinition <=
UnivariateNodeOut1[u,v,q] - 1/2 * (DirectionNeg[u,v,q] + MixCalorificValue[u])
<= SlackUnivariateDefinition;

#p2uv out from the paper
subject to UnivariateNodeOut2Definition{(u,v,q) in ARCS}:
-SlackUnivariateDefinition<=
UnivariateNodeOut2[u,v,q] - 1/2 * (DirectionNeg[u,v,q] - MixCalorificValue[u])
<=SlackUnivariateDefinition;

#y1uv in from the paper
subject to UnivariateArcIn1Definition{(u,v,q) in ARCS}:
-SlackUnivariateDefinition<=
UnivariateArcIn1[u,v,q] - 1/2 * (DirectionPos[u,v,q] + CalorificArcVar[u,v,q])
<= SlackUnivariateDefinition;

#y2uv in from the paper
subject to UnivariateArcIn2Definition{(u,v,q) in ARCS}:
-SlackUnivariateDefinition<=
UnivariateArcIn2[u,v,q] - 1/2 * (DirectionPos[u,v,q] - CalorificArcVar[u,v,q])
<= SlackUnivariateDefinition;

#y1uv out from the paper
subject to UnivariateArcOut1Definition{(u,v,q) in ARCS}:
-SlackUnivariateDefinition <=
UnivariateArcOut1[u,v,q] - 1/2 * (DirectionNeg[u,v,q] + CalorificArcVar[u,v,q])
<= SlackUnivariateDefinition;

#y2uv out from the paper
subject to UnivariateArcOut2Definition{(u,v,q) in ARCS}:
-SlackUnivariateDefinition<=
UnivariateArcOut2[u,v,q] - 1/2 * (DirectionNeg[u,v,q] - CalorificArcVar[u,v,q])
<= SlackUnivariateDefinition;


subject to massbalance{u in NODES}:
FlowInOut[u] = sum{(u,v,q) in ARCS} FlowArcVar[u,v,q] - sum{(v,u,q) in ARCS} FlowArcVar[v,u,q];

subject to pressurebalance{(u,v,q) in PIPES}:
-SlackPressure <=
PressureVar[v]**2 - PressureVar[u]**2  + Phi[u,v,q]
<= SlackPressure;

subject to pressurebalance2{(u,v,q) in SHORTPIPES union VALVES union RESISTORS}:
PressureVar[v] = PressureVar[u];

# Note (10**6) is divided to make sure convert units (m^4/s^4) into Pa (m^4/(s^4*10^(-6))) while (100000^2) is to change pressure unit Pa from Bar.

subject to pressurelossinpipe{(u,v,q) in PIPES}:
Phi[u,v,q] = FrictionFactor[u,v,q] * (
(DirectionPos[u,v,q]/(1000**2))**2 - (DirectionNeg[u,v,q]/(1000**2))**2
)/(100000**2);

subject to pressureincompresser{(u,v,q) in COMPRESSORS}: PressureChangeVar[u,v,q] = PressureVar[v] - PressureVar[u];

subject to pressureincontrolvavle{(u,v,q) in CONTROLVALVES}: PressureChangeVar[u,v,q] = PressureVar[u] - PressureVar[v];

subject to exitheatpowerupperbound{u in SINKS}: MixCalorificValue[u]*FlowInOut[u] <= HeatPowerUpper[u];
subject to exitheatpowerlowerbound{u in SINKS}: MixCalorificValue[u]*FlowInOut[u] >= HeatPowerLower[u];

subject to Flowsplittingone{(u,v,q) in ARCS}: FlowArcVar[u,v,q] = DirectionPos[u,v,q] - DirectionNeg[u,v,q];
subject to Flowsplittingtwo{(u,v,q) in ARCS}: DirectionNeg[u,v,q] <= (Direction[u,v,q]-1)*FlowLowerArc[u,v,q];
subject to Flowsplittingthree{(u,v,q) in ARCS}: DirectionPos[u,v,q] <= Direction[u,v,q]*FlowUpperArc[u,v,q];

subject to mixingnonsource{u in NODES diff SOURCES}:
       -SlackMixingNonSource <=
       (sum{(v,u,q) in ARCS}( UnivariateNodeIn1[v,u,q]**2 - UnivariateNodeIn2[v,u,q]**2) ) +
       (sum{(u,v,q) in ARCS}(UnivariateNodeOut1[u,v,q]**2 - UnivariateNodeOut2[u,v,q]**2)) -
       (sum{(v,u,q) in ARCS}(UnivariateArcIn1[v,u,q]**2 - UnivariateArcIn2[v,u,q]**2)) -
       (sum{(u,v,q) in ARCS}(UnivariateArcOut1[u,v,q]**2 - UnivariateArcOut2[u,v,q]**2))
       <= SlackMixingNonSource;

subject to mixingsourcenode{u in SOURCES}:
       -SlackMixingSource <=
       MixCalorificValue[u]*FlowInOut[u] +
       (sum{(v,u,q) in ARCS} (UnivariateNodeIn1[v,u,q]**2 - UnivariateNodeIn2[v,u,q]**2)) +
       (sum{(u,v,q) in ARCS} (UnivariateNodeOut1[u,v,q]**2 - UnivariateNodeOut2[u,v,q]**2)) -
       CalorificValue[u]*FlowInOut[u]-
       (sum{(v,u,q) in ARCS} (UnivariateArcIn1[v,u,q]**2 - UnivariateArcIn2[v,u,q]**2)) -
       (sum{(u,v,q) in ARCS} (UnivariateArcOut1[u,v,q]**2 - UnivariateArcOut2[u,v,q]**2))
       <= SlackMixingNonSource;

subject to propagationoutwardupper{(u,v,q) in ARCS}: (MixCalorificValue[u] -CalorificArcVar[u,v,q])
                                   <= (CalorificUpper - CalorificLower)*(1-Direction[u,v,q]);

subject to propagationoutwardlower{(u,v,q) in ARCS}: (MixCalorificValue[u] -CalorificArcVar[u,v,q])
                        >= -(CalorificUpper - CalorificLower)*(1-Direction[u,v,q]);

subject to propagationinwardupper{(v,u,q) in ARCS}: (MixCalorificValue[u] -CalorificArcVar[v,u,q])
                       <= (CalorificUpper - CalorificLower)*Direction[v,u,q];

subject to propagationinwardlower{(v,u,q) in ARCS}: (MixCalorificValue[u] -CalorificArcVar[v,u,q])
                        >= -(CalorificUpper - CalorificLower)*Direction[v,u,q];

