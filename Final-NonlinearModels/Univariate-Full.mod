### Nonlinear univariate model. All nonlinearities in this model
### arise from quadratic terms x^2. This is achieved by reformulating
### the mixing constraints via a univariate reformulation. Furthermore
### the pressure loss models are reformulated using the positive
### and negative flow variables instead of the absolute value of
### q. This makes the pressure loss smooth however has the downside
### that the derivative does not match at zero.
### This is the full version consisting of the model with shared data copied in
### directly. This is needed to work correctly with Neos server.

### Sets used across all models

set NODES;   # This is the set of all nodes (V)
set SOURCES; # Subset of NODES, (V+)
set SINKS;   # Subset of NODES, (V-)
set NAMES;   # Names of each pipe to make it three dimensional
set ARCS within (NODES cross NODES cross NAMES);            # (A)
set PIPES within (NODES cross NODES cross NAMES);           # Subset of ARCS (A_pi)
set COMPRESSORS within (NODES cross NODES cross NAMES);     # Subset of ARCS (A_cm)
set CONTROLVALVES within (NODES cross NODES cross NAMES);   # Subset of ARCS (A_cv)
set SHORTPIPES within (NODES cross NODES cross NAMES);      # Subset of ARCS (A_sp)
set RESISTORS within (NODES cross NODES cross NAMES);       # Subset of ARCS (A_r)
set UNI = COMPRESSORS union CONTROLVALVES;                  # Subset of ARCS (A_cm U A_cv)
set VALVES within (NODES cross NODES cross NAMES);          # Subset of ARCS (A_v)

### Parameters ###

## Constants

# universal gas constant (R)
param UnivGasConstant = 8.3144621;

# gravity acceleration (g)
param Gravity = 9.80665;

# Globally calculated parameters. These are calculated in Python

# Average Molar mass entering gas network (M)
param AvgMolarMass;

# Average Temperature of gas entering network (T)
param AvgGasTemp;

# Average PseudoCritical Temperature (T_c)
param AvgPseudoTemp;

# Average PseudoCritical Pressure (P_c)
param AvgPseudoPressure;

# Specific gas constant with average molar mass (R)
param AvgGasConstant = UnivGasConstant/AvgMolarMass;

# Mean of average of Pressure bounds for sources (P_c)
param AvgPressure;


## Node parameters

# flow in/out (q_nom) #
param FlowInOut{u in NODES};

# pressure lower bound per node (p_lower)
param PressureLower{u in NODES};

# pressure upper bound per node (p_upper)
param PressureUpper{u in NODES};

## Source parameters

# Gas temp param
param GasTemperature{u in SOURCES};

# Molar Mass for gas
param MolarMass{u in SOURCES};

# calorific value of suppled gas (H_sup or H_c)
param CalorificValue{u in SOURCES};

# calorific upper: max across Hc_sup (H_upper)
param CalorificUpper = max{u in SOURCES} CalorificValue[u];

# calorific lower: min across Hc_sup (H_lower)
param CalorificLower = min{u in SOURCES} CalorificValue[u];


## Sink parameters

# node flow lower bound per node (q_lower)
param FlowLowerNode{u in SINKS};

# node flow upper bound per node (q_upper)
param FlowUpperNode{u in SINKS};


## Arc parameters

# flow lower bound for eac arc (q_lower)
param FlowLowerArc{(u,v,q) in ARCS};

# flow upper bound (q_upper)
param FlowUpperArc{(u,v,q) in ARCS};

## Pipe parameters

# pressure change upper bound.(delta_upper)
param PressureChangeUpper{(u,v,q) in UNI};

# pressure change lower bound (delta_lower)
param PressureChangeLower{(u,v,q) in UNI};

# mean compressibility (chapter 2 page 20)
param MeanCompressibility = 1 - 3.52*(AvgPressure/AvgPseudoPressure)*exp(-2.26*AvgGasTemp/AvgPseudoTemp) + 0.274*(AvgPressure/AvgPseudoPressure)**2*exp(-1.878*AvgGasTemp/AvgPseudoTemp);

# flow weighted mean of the calorific value supplied at all nodes (H_cm)
param MeanCalorificValue = (sum{u in SOURCES}(FlowInOut[u]*CalorificValue[u]))/(sum{u in SOURCES}(FlowInOut[u]));


## Sink parameters

# heat power lower bound (\underbar{P}_u)
param HeatPowerLower{u in SINKS} = 1.1*MeanCalorificValue*(FlowLowerNode[u]);

# heat power upper bound (\bar{P}_u)
param HeatPowerUpper{u in SINKS} = 0.9*MeanCalorificValue*(FlowUpperNode[u]);

## Phi parameters

#diameter of pipe (D) m
param Diameter{(u,v,q) in PIPES};

# Length of pipe (L) m
param Length{(u,v,q) in PIPES};

#area of pipe (A) m**2
param pi = 4 * atan(1);
param Area{(u,v,q) in PIPES} = pi*(Diameter[u,v,q]/2)**2;

# specific gas constant J/(kg*K)
param SpecificGasConstant = UnivGasConstant/AvgMolarMass;

# roughness of pipe (k) m
param Roughness{(u,v,q) in PIPES};

# friction parameter unitless
param Beta{(u,v,q) in PIPES} = Roughness[u,v,q]/(3.71*Diameter[u,v,q]);

# friction factor of pipe a (from High detail) (lambda with tilda) unitless
#param FrictionFactor{(u,v,q) in PIPES} = (2*log10(Beta[u,v,q]))**(2);

# friction parameter lambda of pipe a (from High detail) (unitless)
# From Chapter 2 equation 2.19
# This is for the turbulent case and phi approx
param Lambda{(u,v,q) in PIPES} = (2*log10(Beta[u,v,q])+1.138)**(-2);

# Dynamic viscosity. This is an estimate for the viscosity units are m**2/s
param Eta = 10**(-6);

# Gamma used to have units for pressure  1/m**5
# This is from various sources, one is Chapter 2 equation 2.25
# Chapter 6 has a description in equation 6.4
param Gamma{(u,v,q) in PIPES} = Length[u,v,q]*SpecificGasConstant*AvgGasTemp* MeanCompressibility
/(Area[u,v,q]**2*Diameter[u,v,q]);

# This is the coefficient of the phi approximation
# which is gamma times littlvae lambda
# This is from chapter 6 6.14
param FrictionFactor{(u,v,q) in PIPES} = Gamma[u,v,q]*Lambda[u,v,q];

# modeler parameters NOTE This is chosen by the modeler. unitless.
param e{(u,v,q) in PIPES};

# This is caculated from MATLAB and used to calculate param d. unitless.
param d{(u,v,q) in PIPES};

# friction factor of alpha m**3/s
param Alpha{(u,v,q) in PIPES} = 2.51*Area[u,v,q]*Eta/Diameter[u,v,q];

# friction parameter delta NOTE This is lower case delta in formulation m**3/s
param Epsilon{(u,v,q) in PIPES} = 2*Alpha[u,v,q]/(Beta[u,v,q]*log(10));

# friction parameter b, m**3/s
param b{(u,v,q) in PIPES} = 2*Epsilon[u,v,q];

# friction parameter c , m**6/s**2
param c{(u,v,q) in PIPES} = (log(Beta[u,v,q])+1)*Epsilon[u,v,q]**(2) - ((e[u,v,q]**(2))/2);

# Slack Parameter
param SlackPressure = 0.01;

param SlackMixingNonSource = 0.01;

param SlackMixingSource = 0.01;

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

