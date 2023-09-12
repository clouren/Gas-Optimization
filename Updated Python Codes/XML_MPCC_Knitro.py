#!/usr/bin/env python
# coding: utf-8

import importlib
import sys

Network_File_Name = sys.argv[1]
Scenario_File_Name = sys.argv[2]


def makeGasXML(model_file, data_file):
    ampl_dat_file = 'XML_MPCC/' + model_file.split('.')[0] + '_' + data_file.split('_')[1] + data_file.split('_')[2] + '.xml'
    print(ampl_dat_file)
    lines = ['<document>']
    lines.append('<category>minco</category>')
    lines.append('<solver>Baron</solver>')
    lines.append('<inputMethod>AMPL</inputMethod>')
    lines.append('<email><![CDATA[m233246@usna.edu]]></email>')
    lines.append('<client><![CDATA[Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15@136.160.90.65]]></client>')
    lines.append('<priority><![CDATA[long]]></priority>')
    lines.append('<model><![CDATA[') 
    with open(model_file, 'r') as f:
        contents = f.read()
    lines.append(contents)
    lines.append(']]></model>')
    lines.append('<data><![CDATA[data;')
    
    with open(data_file, 'r') as f:
        contents = f.read()
    lines.append(contents)
    lines.append(']]></data>')
    lines.append('<commands><![CDATA[option relax_integrality 0;')
    lines.append('option baron_options "maxtime = 3600";' )
    lines.append('solve; display _total_solve_time;]]></commands>')
    lines.append('<comments><![CDATA[]]></comments>')
    lines.append('</document>')
    
    with open(ampl_dat_file, 'w+') as f:
        f.write('\n'.join(lines))
        

makeGasXML(Network_File_Name, Scenario_File_Name)
