#!/usr/bin/env python
# coding: utf-8

# In[9]:


"""
Created on Fri Sep 9 11:15:51 2022

@author: author

This module is to auto generate data class for .net and .scn files

The module requries to install beautifulsoup4 and lxml.

#!pip install beautifulsoup4
#!pip install lxml

Functions:
    translate_field_name()
    makeScenarioDF()
    makeNetworkDF()
    get_objects()
    validateUnit()
    
"""

from collections import defaultdict
from bs4 import BeautifulSoup
from dataclasses import dataclass, field
from pprint import pprint

import numpy as np
import pandas as pd
from dataclasses import dataclass

# Define data classes
@dataclass
class CompressorStation:
    name: str = ""
    alias: str = ""
    diameterIn: float = 0
    diameterOut: float = 0
    dragFactorIn: float = 0
    dragFactorOut: float = 0
    flowMax: float = 0
    flowMin: float = 0
    _from: str = ""
    fuelGasVertex: str = ""
    gasCoolerExisting: float = 0
    internalBypassRequired: float = 0
    pressureLossIn: float = 0
    pressureLossOut: float = 0
    pressureInMin: float = 0
    pressureOutMax: float = 0
    to: str = ""

@dataclass
class Pipe:
    name: str = ""
    alias: str = ""
    diameter: float = 0
    flowMax: float = 0
    flowMin: float = 0
    _from: str = ""
    heatTransferCoefficient: float = 0
    length: float = 0
    pressureMax: float = 0
    roughness: float = 0
    to: str = ""
        
@dataclass
class Innode:
    name: str = ""
    alias: str = ""
    geoWGS84Lat: float = 0
    geoWGS84Long: float = 0
    height: float = 0
    pressureMax: float = 0
    pressureMin: float = 0
    x: float = 0
    y: float = 0

@dataclass
class Source:
    name: str = ""
    alias: str = ""
    calorificValue: float = 0
    coefficient_A_heatCapacity: float = 0
    coefficient_B_heatCapacity: float = 0
    coefficient_C_heatCapacity: float = 0
    flowMax: float = 0
    flowMin: float = 0
    gasTemperature: float = 0
    geoWGS84Lat: float = 0
    geoWGS84Long: float = 0
    height: float = 0
    molarMass: float = 0
    normDensity: float = 0
    pressureMax: float = 0
    pressureMin: float = 0
    pseudocriticalPressure: float = 0
    pseudocriticalTemperature: float = 0
    x: float = 0
    y: float = 0
    # The following is populated from .scn
    scenario: dict = field(default_factory=dict)
    
    def get_flow(self):
        for key, value in self.scenario.items():
            if key[0] == 'flow':
                return value
        return 0

@dataclass
class Sink:
    name: str = ""
    alias: str = ""
    flowMax: float = 0
    flowMin: float = 0
    geoWGS84Lat: float = 0
    geoWGS84Long: float = 0
    height: float = 0
    pressureMax: float = 0
    pressureMin: float = 0
    x: float = 0
    y: float = 0
    # The following is populated from .scn
    scenario: dict = field(default_factory=dict)
        
    def get_flow(self):
        for key, value in self.scenario.items():
            if key[0] == 'flow':
                return value
        return 0
        
@dataclass
class Controlvalve:
    name: str = ""
    alias: str = ""
    flowMax: float = 0
    flowMin: float = 0
    _from: str = ""
    gasPreheaterExisting: float = 0
    internalBypassRequired: float = 0
    pressureDifferentialMax: float = 0
    pressureDifferentialMin: float = 0
    pressureInMin: float = 0
    pressureLossIn: float = 0
    pressureLossOut: float = 0
    pressureOutMax: float = 0
    to: str = ""

@dataclass
class ShortPipe:
    name: str = ""
    flowMax: float = 0
    flowMin: float = 0
    _from: str = ""
    to: str = ""
    alias: str=""

@dataclass
class Resistor:
    name: str = ""
    diameter: float = 0
    dragFactor: float = 0
    flowMax: float = 0
    flowMin: float = 0
    _from: str = ""
    to: str = ""
    alias: str=""
        
@dataclass
class Valve:
    name: str = ""
    alias: str = ""
    flowMax: float = 0
    flowMin: float = 0
    _from: str = ""
    gasPreheaterExisting: float = 0
    internalBypassRequired: float = 0
    pressureDifferentialMax: float = 0
    pressureDifferentialMin: float = 0
    pressureInMin: float = 0
    pressureLossIn: float = 0
    pressureLossOut: float = 0
    pressureOutMax: float = 0
    to: str = ""
        
# @dataclass
# class Node:
#     name: str = ""
#     type: str = ""
#     flow: float = 0
#     pressurelower: float = 0
#     pressureupper: float = 0



# Function for formatting of the object
def translate_field_name(f):
            # can't have a field called from and can't have hyphens
    return f'{"_" if f == "from" else ""}{f.replace("-", "_")}'


# Function that loads .net file and generate net_df

def makeNetworkDF(filename):    

    # Reading the data inside the xml
    # file to a variable under the name
    # data
    with open(filename, 'r') as f:
        data = f.read()

    # Passing the stored data inside
    # the beautifulsoup parser, storing
    # the returned object
    net_data = BeautifulSoup(data, "xml")


    # we'll use the fact that the structure is network 
    data_types = {('node', 'nodes', s.name) for s in net_data.find('network').find('nodes').children if s.name is not None}


    data_types |= {('connection', 'connections', s.name) for s in net_data.find('network').find('connections').children if s.name is not None}
    
    


    #nodes = defaultdict(dict)
    #node_types = {'source'}
    rows = []
    for category, tag, data_type in data_types:
        for node in net_data.find('network').find(tag).find_all(data_type):
            name = node.attrs['id']
            for k, v in node.attrs.items():
                if k == 'id':
                    continue
                rows.append({'category':category,
                             'type':data_type,
                             'name':name,
                             'field':k,
                             'value':v,
                            'unit':''})
            for s in node.children:
                if s.name is None:
                    #None -- works fine without it.
                    continue
                rows.append({'category':category,
                             'type':data_type,
                             'name':name,
                             'field':s.name,
                             'value':s.attrs.get('value'),
                             'unit':s.attrs.get('unit', '')})


        # this will be a data frame where each row is a single attribute for a network element
        # each network element will have a bunch of rows
        net_df = pd.DataFrame(rows)
        
    checker = ((net_df
                 .groupby(['category', 'type', 'field', 'unit'])
                 .name.count().reset_index()
                 .groupby(['category', 'type', 'field'])
                .unit.count()
                .reset_index())
               .unit.max())
    
#     if checker != 1:
#         print("unit is inconsistent")
        
    return pd.DataFrame(rows)
            


# In[20]:


def makeScenarioDF(filepath):
    #print(f'makeScenarioDF({filepath})')

    # Reading the data inside the xml
    # file to a variable under the name
    # data
    with open(filepath, 'r') as f:
        data = f.read()

    # Passing the stored data inside
    # the beautifulsoup parser, storing
    # the returned object
    scn_data = BeautifulSoup(data, "xml")

    # we'll use the fact that the structure is network 
    data_types = {('node', 'scenario', s.name) for s in scn_data.find('boundaryValue').find('scenario').children if s.name is not None}

        # This is to ensure this script file is working for 582 nodes scenario files.
#    data_types = {(i,j,k) for i,j,k in data_types if k != 'scenarioProbability'}
    
    rows = []
    for category, tag, data_type in data_types:
        if data_type == 'scenarioProbability':
            continue
        for node in scn_data.find('boundaryValue').find(tag).find_all(data_type):
            if node.name is None:
                continue
            try:
                name = node.attrs['id']
            except Exception as e:
                print(category, tag, data_type, node)
                raise e
            for k, v in node.attrs.items():
                if k == 'id':
                    continue
                rows.append({'category':category,
                             'type':data_type,
                             'name':name,
                             'field':k,
                             'value':v,
                             'unit':''})
                
            for s in node.children:
                if s.name is None:
                    continue
                rows.append({'category':category,
                             'type':data_type,
                             'name':name,
                             'field':s.name,
                             'value':s.attrs.get('value', ''),
                             'bound':s.attrs.get('bound', ''),
                             'unit':s.attrs.get('unit', '')})

    # this will be a data frame where each row is a single attribute for a network element
    # each network element will have a bunch of rows
    scn_df = pd.DataFrame(rows)
    
    ## To create a new column incorportating bounds
    field2 = []
    for bound in scn_df["bound"]:
        if bound == 'lower':
            field2.append("pressurelower")
        elif bound == 'upper':
            field2.append("pressureupper")
        elif bound == 'both':
            field2.append("flow")
        else:
            field2.append("type")
    scn_df["field2"] =  field2
    
    # this is to check whether unit is consistent.
    checker = (scn_df
 .groupby(['category', 'type', 'field2', 'unit'])
 .name.count().reset_index()
 .groupby(['category', 'type', 'field2']).unit.count().reset_index()).unit.max()
    
    #if checker != 1:
     #   print("units are inconsistent.")
        
    return(scn_df)


# In[18]:


# This grabs net_df and scn_df files and produce objects as we needed.

def get_objects(net_filepath, scn_filepath):
#     types = [('connection', 'compressorStation'),
#          ('connection', 'pipe'),
#          ('node', 'innode'),
#          ('node', 'source'),
#          ('node', 'sink')]

    net_df = makeNetworkDF(net_filepath)
    scn_df = makeScenarioDF(scn_filepath)
    new_rows = ['from dataclasses import dataclass', '']
    field_types = defaultdict(lambda:'float = 0')
    field_types['from'] = 'str = ""'
    field_types['to'] = 'str = ""'
    field_types['alias'] = 'str = ""'
    field_types['fuelGasVertex'] = 'str = ""'

    
    constructors = {'compressorStation': lambda x:CompressorStation(**x),
                    'pipe': lambda x:Pipe(**x),
                    'source': lambda x:Source(**x),
                    'sink': lambda x:Sink(**x),
                    'innode': lambda x:Innode(**x),
                    'controlValve': lambda x:Controlvalve(**x),
                    'shortPipe': lambda x:ShortPipe(**x),
                    'resistor': lambda x:Resistor(**x),
                    # add one more line for node from the .scn file
                    'node': lambda x:Node(**x),
                    'valve': lambda x:Valve(**x)}

    objects = {}
    
    items = set(zip(net_df['type'], net_df.name))
    for data_type, name in items:
        if data_type in constructors:            
            this_df = net_df[(net_df['type'] == data_type) & (net_df.name == name)].copy()
            values = {(translate_field_name(k)):(float(v) if 'float' in field_types[k] else v) for k, v in zip(this_df.field, this_df.value)}
            values['name'] = name
            o = constructors[data_type](values)
            objects[(data_type, name)] = o
        else:
            print(f'no dataclass: {data_type}')
                    
    type2class = {'entry':'source', 'exit':'sink'}
    tempdf = scn_df[scn_df['field']=='type']
    # create dictionary {name: value} (value = 'source' or 'sink')
    node2type = {a: type2class[b] for a,b in zip(tempdf.name, tempdf.value)}  
    for name, field, value, bound in zip(scn_df.name, scn_df.field, scn_df.value, scn_df.bound):
        if field == 'type':
            continue
        obj = objects[(node2type[name], name)]
        obj.scenario[(field, bound)] = value
        
    # for key, value in objects.items():
    #     print(f'{key}: {value}')
    return objects


# In[17]:


def validateFields(filepath, *field_input):
    
    ''' 
    validateFields takes a filepath of .net or .scn files adn returns validation of data in the datafile.
    To check specific fiedls, field_input will allow users to input any fields need to be checked.
    '''
    
    types = [('connection', 'compressorStation'),
         ('connection', 'pipe'),
         ('connection', 'controlValve'),
         ('node', 'innode'),
         ('node', 'source'),
         ('node', 'sink')]

    if '.net' in str(filepath):
        net_df = makeNetworkDF(filepath)
        
        if field_input:
            
            for i,k in types:
                if k in field_input:
                    print(net_df.groupby(['category', 'type', 'field', 'unit'])
                        .name.count()[i,k])
                    
        else:
            for i in types:
                print(net_df.groupby(['category', 'type', 'field', 'unit'])
                    .name.count()[i])
                
    else:
        scn_df = makeScenarioDF(filepath)
        print(scn_df.groupby(['category', 'type', 'field2', 'unit'])
              .name.count()[('node', 'node')])    

