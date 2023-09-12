#!/usr/bin/env python
# coding: utf-8

# General XML file maker for Neos cluster
# It takes as input the name of the model file, data file, and solver to be used
# and uses these to generate an XML file to submit to the NEOS cluster.

import importlib
import sys

# A little error handling
if len(sys.argv) != 4:
    print('Expected input Model_File Data_File Solver_Name')
    sys.exit()

# Model and data file are given as input to the function
Model_File_Name = sys.argv[1]
Data_File_Name = sys.argv[2]
Solver_Name = sys.argv[3]

# Set the type of solver
Solver_Type = ''
if Solver_Name == 'Knitro':
    Solver_Type = 'minco'
elif Solver_Name == 'Baron':
    Solver_Type = 'minco'
elif Solver_Name == 'Gurobo':
    Solver_Type = 'milp'
else:
    print('Wrong Solver Name!')
    sys.exit()


def makeGasXML(model_file, data_file):
    # Name of file. The syntax is a little tricky, so it's assuming the current file structure
    dat_name_short = data_file.split('../AMPL-Data-Files/')[1]
    dat_name_short = dat_name_short.split('.dat')[0]
    ampl_dat_file = 'XML_Files/' + model_file.split('.')[0] + '_' + dat_name_short + '.xml'
    print(ampl_dat_file)
    lines = ['<document>']
    # Type of solver that is being used. Options of interest for us are:
    #   minco:  Mixed integer nonlienarly constrainted optimization for Baron and Knitro
    #   milp:   Mixed integer linear program for Gurobi
    #   nco:    Nonlinearly constrained optimization for Knitro
    solver_type_file = '<category>' + Solver_Type + '</category>'
    #lines.append('<category>')
    #lines.append(Solver_Type)
    #lines.append('</category>')
    lines.append(solver_type_file)
    # lines.append('<category>minco</category>')
    # Which solver is being used. Option should be Baron, Knitro, or Gurobi
    solver_name_file = '<solver>' + Solver_Name + '</solver>'
    #lines.append('<solver>')
    #lines.append(Solver_Name)
    #lines.append('</solver>')
    lines.append(solver_name_file)
    # lines.append('<solver>Knitro</solver>')
    # Type of input, should always be AMPL
    lines.append('<inputMethod>AMPL</inputMethod>')
    # Email address
    lines.append('<email><![CDATA[lourenco@usna.edu]]></email>')
    # Next two lines are copied directly from Neos. Should not be modified
    lines.append('<client><![CDATA[Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36@136.160.90.53]]></client>')
    lines.append('<priority><![CDATA[long]]></priority>')
    # Include the AMPL model file
    lines.append('<model><![CDATA[') 
    with open(model_file, 'r') as f:
        contents = f.read()
    lines.append(contents)
    lines.append(']]></model>')
    lines.append('<data><![CDATA[data;')
    
    # Include the AMPL data file
    with open(data_file, 'r') as f:
        contents = f.read()
    lines.append(contents)
    lines.append(']]></data>')
    lines.append('<commands><![CDATA[')
    lines.append('option knitro_options "maxtime_cpu = 3600";')
    lines.append('solve; display _total_solve_time;]]></commands>')
    lines.append('<comments><![CDATA[]]></comments>')
    lines.append('</document>')
    
    with open(ampl_dat_file, 'w+') as f:
        f.write('\n'.join(lines))
        

makeGasXML(Model_File_Name, Data_File_Name)
