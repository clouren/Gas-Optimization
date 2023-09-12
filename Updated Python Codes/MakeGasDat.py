#!/usr/bin/env python
# coding: utf-8

# Create gas data

import GasParsing as gp
import importlib
import numpy as np
import sympy as sym
import math
from datetime import datetime
now = datetime.now()
date_time_str = now.strftime("%y%m%d-%H%M") +'.dat'


def makeGasDat(network_file, scenario_file):
    ampl_dat_file = scenario_file.split('.')[0]+'-'+date_time_str #+ '.dat'
    network = gp.get_objects(network_file, scenario_file)
    
    lines = ['data;']

    lines.append('\n### SETS ###\n')

    # NODES
    lines.append('set NODES :=')
    for data_type, name in network:
        if data_type=='source':
            lines.append(name)
    for data_type, name in network:
        if data_type=='sink':
            lines.append(name)
    for data_type, name in network:
        if data_type=='innode':
            lines.append(name)
    lines.append(';')    

    # SOURCES
    lines.append('\nset SOURCES :=')
    for data_type, name in network:
        if data_type=='source':
            lines.append(name)
    lines.append(';')    

    # SINKS
    lines.append('\nset SINKS :=')
    for data_type, name in network:
        if data_type=='sink':
            lines.append(name)
    lines.append(';')
    
    # NAMES
    lines.append('\nset NAMES :=')
    for data_type, name in network:
        if data_type=='pipe':
            obj = network[(data_type, name)]
            lines.append(name)

    for data_type, name in network:
        if data_type=='compressorStation':
            obj = network[(data_type, name)]
            lines.append(name)
            
    for data_type, name in network:
        if data_type=='valve':
            obj = network[(data_type, name)]
            lines.append(name)
            
    for data_type, name in network:
        if data_type=='shortPipe':
            obj = network[(data_type, name)]
            lines.append(name)

    for data_type, name in network:
        if data_type=='resistor':
            obj = network[(data_type, name)]
            lines.append(name)
            
    for data_type, name in network:
        if data_type=='controlValve':
            obj = network[(data_type, name)]
            lines.append(name)
                    
    lines.append(';')
    
    
    # ARCS
    lines.append('\nset ARCS :=')
    for data_type, name in network:
        if data_type=='pipe':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = name
            temp = f'({in_node}, {out_node}, {arc_id})'
            lines.append(temp)

    for data_type, name in network:
        if data_type=='compressorStation':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'({in_node}, {out_node}, {arc_id})'
            lines.append(temp)
            
    for data_type, name in network:
        if data_type=='valve':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'({in_node}, {out_node}, {arc_id})'
            lines.append(temp)
            
    for data_type, name in network:
        if data_type=='shortPipe':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'({in_node}, {out_node}, {arc_id})'
            lines.append(temp)

    for data_type, name in network:
        if data_type=='resistor':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'({in_node}, {out_node}, {arc_id})'
            lines.append(temp)
            
    for data_type, name in network:
        if data_type=='controlValve':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'({in_node}, {out_node}, {arc_id})'
            lines.append(temp)
                    
    lines.append(';')    

    # PIPES
    lines.append('\nset PIPES :=')
    for data_type, name in network:
        if data_type=='pipe':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'({in_node}, {out_node}, {arc_id})'
            lines.append(temp)
    lines.append(';')    

    # COMPRESSIONSTATIONS
    lines.append('\nset  COMPRESSORS:=')
    for data_type, name in network:
        if data_type=='compressorStation':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'({in_node}, {out_node}, {arc_id})'
            lines.append(temp)
    lines.append(';')
    
    # CONTROLVALVES
    lines.append('\nset  CONTROLVALVES:=')
    for data_type, name in network:
        if data_type=='controlValve':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'({in_node}, {out_node}, {arc_id})'
            lines.append(temp)
        else:
            continue
            
    lines.append(';')
            
    # VALVES
    lines.append('\nset  VALVES:=')
    for data_type, name in network:
        if data_type=='valve':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'({in_node}, {out_node}, {arc_id})'
            lines.append(temp)
        else:
            continue
            
    lines.append(';')
            
    # SHORTPIPES
    lines.append('\nset  SHORTPIPES:=')
    for data_type, name in network:
        if data_type=='shortPipe':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'({in_node}, {out_node}, {arc_id})'
            lines.append(temp)
        else:
            continue
            
    lines.append(';')
            
    # RESISTORS
    lines.append('\nset  RESISTORS:=')
    for data_type, name in network:
        if data_type=='resistor':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'({in_node}, {out_node}, {arc_id})'
            lines.append(temp)
        else:
            continue
            
    lines.append(';')
    
    
    
    lines.append('\n### PARAMS ###\n')

    lines.append('\n# for NODES')
    lines.append('param: FlowInOut PressureLower PressureUpper :=')

    for data_type, name in network:
        if data_type=='source':
            obj = network[(data_type, name)]
            flow = obj.get_flow()
            # TODO Conversion to kg/s
            flow = float(flow)*(1000/3600)
            if (flow < 0):
                flow = -flow
            lines.append(f'{name} {flow} {obj.pressureMin} {obj.pressureMax}')

    for data_type, name in network:        
        if data_type == 'sink':
            obj = network[(data_type, name)]
            flow = obj.get_flow()
            flow = float(flow)*(1000/3600)
            if (flow > 0):
                flow = -flow
            lines.append(f'{name} {flow} {obj.pressureMin} {obj.pressureMax}')

    for data_type, name in network:        
            # Innode doesn't have flow, flowMin and flowMax so manually input value -inf (put it in class)
        if data_type == 'innode':
            obj = network[(data_type, name)]
            lines.append(f'{name} {0} {obj.pressureMin} {obj.pressureMax}')
    lines.append(';')
    
    lines.append('\n# for Mean molar mass')

   
    flow_list = []
    weighted_molarmass = []
    weighted_gasTemp = []
    weighted_pressure = []
    weighted_pseudopressure = []
    weighted_pseudotemp = []
    
    for data_type, name in network:
        if data_type == 'source':
            obj = network[(data_type, name)]
            flow = obj.get_flow()
            flow = float(flow)
            flow_list.append(flow)
            weighted_molarmass.append(float(obj.molarMass) * float(flow))
            weighted_gasTemp.append(float(obj.gasTemperature) * float(obj.molarMass))
            weighted_pressure.append((float(obj.pressureMin) + float(obj.pressureMax))*0.5*float(flow))
            weighted_pseudopressure.append(float(obj.pseudocriticalPressure) * float(flow))
            weighted_pseudotemp.append(float(obj.pseudocriticalTemperature) * float(flow))

    Avg_MolarMass = sum(weighted_molarmass)/sum(flow_list)/1000 # Conversion from Kmol to mol
    # Conversion to Kelvin
    Avg_GasTemp = (sum(weighted_gasTemp)/sum(flow_list)) + float(273.15)
    Avg_Pressure = sum(weighted_pressure)/sum(flow_list)
    Avg_Pseudopressure = sum(weighted_pseudopressure)/sum(flow_list)
    Avg_Pseudotemp = sum(weighted_pseudotemp)/sum(flow_list)
    Avg_Compressibility = 1 - 3.52*(Avg_Pressure/Avg_Pseudopressure)*math.exp(-2.26*Avg_GasTemp/Avg_Pseudotemp) + 0.274*(Avg_Pressure/Avg_Pseudopressure)**2*math.exp(-1.878*Avg_GasTemp/Avg_Pseudotemp)
    Specific_GasConstant = 8.314462/Avg_MolarMass
    
    
    lines.append('param AvgMolarMass =')
    lines.append(f'{Avg_MolarMass}')
    lines.append(';')
    
    lines.append('param AvgGasTemp =')
    lines.append(f'{Avg_GasTemp}')
    lines.append(';')
    
    lines.append('param AvgPressure =')
    lines.append(f'{Avg_Pressure}')
    lines.append(';')
    
    lines.append('param AvgPseudoPressure =')
    lines.append(f'{Avg_Pseudopressure}')
    lines.append(';')
    
    lines.append('param AvgPseudoTemp =')
    lines.append(f'{Avg_Pseudotemp}')
    lines.append(';')
            
    lines.append('\n# for SOURCES')
    lines.append('param: CalorificValue GasTemperature MolarMass:=')

    for data_type, name in network:
        if data_type == 'source':
            obj = network[(data_type, name)]
            lines.append(f'{name} {obj.calorificValue*np.random.uniform(0.9,1.1)} {obj.gasTemperature} {obj.molarMass}')
    lines.append(';')                

    lines.append('\n# for SINKS')
    lines.append('param: FlowLowerNode FlowUpperNode :=')
    for data_type, name in network:        
        if data_type == 'sink':
            obj = network[(data_type, name)]
            flowMax = obj.flowMax
            flowMin = obj.flowMin
            flowMax = float(flowMax)*(1000/3600)
            flowMin = float(flowMin)*(1000/3600)
            #if (flowMax > 0):
            #    flowMax = -flowMax
            #if (flowMin > 0):
            #    flowMin = -flowMin
            Flowlower = -max(abs(flowMax),abs(flowMin))
            Flowupper = min(0,flowMax)
            lines.append(f'{name} {Flowlower} {Flowupper}')
    lines.append(';')        

    # ARCS PARAMETERS
    lines.append('\n# for ARCS')
    lines.append('param: FlowLowerArc FlowUpperArc :=')

    for data_type, name in network:
        if data_type == 'pipe':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'{in_node} {out_node} {arc_id}'
            lines.append(f'{temp} {obj.flowMin*(1000/3600)} {obj.flowMax*(1000/3600)}')

    for data_type, name in network:        
        if data_type == 'compressorStation':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'{in_node} {out_node} {arc_id}'
            lines.append(f'{temp} {obj.flowMin*(1000/3600)} {obj.flowMax*(1000/3600)}')
            
    for data_type, name in network:        
        if data_type == 'shortPipe':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'{in_node} {out_node} {arc_id}'
            lines.append(f'{temp} {obj.flowMin*(1000/3600)} {obj.flowMax*(1000/3600)}')
            
    for data_type, name in network:        
        if data_type == 'resistor':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'{in_node} {out_node} {arc_id}'
            lines.append(f'{temp} {obj.flowMin*(1000/3600)} {obj.flowMax*(1000/3600)}')
            
    for data_type, name in network:        
        if data_type == 'valve':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'{in_node} {out_node} {arc_id}'
            lines.append(f'{temp} {obj.flowMin*(1000/3600)} {obj.flowMax*(1000/3600)}')
            
    for data_type, name in network:        
        if data_type == 'controlValve':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'{in_node} {out_node} {arc_id}'
            lines.append(f'{temp} {obj.flowMin*(1000/3600)} {obj.flowMax*(1000/3600)}')
           
    lines.append(';')   

    # This value is not given; Further review needed
    # lines.append('param: MeanTemp :=')
    # for data_type, name in network:
    #     if data_type == 'pipe':
    #         obj = network[(data_type, name)]
    #         lines.append(f'{name} {}')

    # PIPE PARAMETERS
    lines.append('\n# for PIPES')
    lines.append('param: Roughness Diameter Length e d :=') 
    
    for data_type, name in network:
        if data_type == 'pipe':
            # Update the calculated parameters
            # so they match ampl
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'{in_node} {out_node} {arc_id}'
            obj.diameter = obj.diameter / 1000 # This is because we are converting from mm to m
            obj.roughness = obj.roughness / 1000 # Also in mm
            obj.length = obj.length*1000 # Conversion from km to m
            pi = np.pi
            v = 10**(-6) # m**2/s
            g = 9.80665 # m/s**2
            beta = obj.roughness/(obj.diameter*3.71) #unitless
            alpha = 2.51 * pi * v * obj.diameter /4 # m**3/s
            #gamma = 8*obj.length / (pi**(2) * g * obj.diameter**(5)) # s**2/m**5
            gamma = obj.length * Specific_GasConstant * Avg_GasTemp * Avg_Compressibility/( (pi*(obj.diameter/2)**2 )**2 * obj.diameter)
            delta = 2*alpha / (beta*np.log(10))

            # Now, we calculate the approximation using
            # the equations in Appendix for pressure loss
            a = sym.Symbol('a')
            e_squared_coeff = obj.diameter/2;
            e_coeff = 2*delta * obj.diameter - 64*10**(-6) * (obj.diameter/2)**2*pi * (2*np.log10(beta))**2
            constant_term = (np.log(beta)+1)*delta**2
            # Pick the second one because it is the positive root
            ad = sym.solve(e_squared_coeff*a**2 +e_coeff*a + constant_term, a)[1]
            #ad0 = sym.solve(e_squared_coeff*a**2 +e_coeff*a + constant_term, a)[0]
            # print(f'The first is {ad0} and the second is {ad}')

            #A = 0.5
            #B = ((2*delta) - 128*obj.length*v*(4*np.log10(beta)**2
            #        /(pi*g*obj.diameter**(4)*gamma)))
            #C = (np.log(beta) + 1)*delta**2

            
            lines.append(f'{temp} {obj.roughness} {obj.diameter} {obj.length} {ad} {ad}')
    lines.append(';')          
    
    # COMPRESSOR STATIONS AND CONTROLVAVLES PARAMETERS
    lines.append('\n# for COMPRESSORSTATIONS & CONTROLVAVES')
    lines.append('param:  PressureChangeUpper PressureChangeLower :=')

    for data_type, name in network:
        if data_type == 'compressorStation':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'{in_node} {out_node} {arc_id}'
            lines.append(f'{temp} {obj.pressureOutMax - obj.pressureInMin} {0}')

    for data_type, name in network:        
        if data_type == 'controlValve':
            obj = network[(data_type, name)]
            in_node = obj._from
            out_node = obj.to
            arc_id = obj.name
            temp = f'{in_node} {out_node} {arc_id}'
            lines.append(f'{temp} {obj.pressureOutMax - obj.pressureInMin} {0}')
    lines.append(';')   
    
    with open(ampl_dat_file, 'w') as f:
        f.write('\n'.join(lines))
