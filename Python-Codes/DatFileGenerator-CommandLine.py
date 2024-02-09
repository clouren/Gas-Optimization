#!/usr/bin/env python
# coding: utf-8

import importlib
import MakeGasDat as mg
import sys

Network_File_Name = sys.argv[1]
Scenario_File_Name = sys.argv[2]

importlib.reload(mg)
mg.makeGasDat(Network_File_Name, Scenario_File_Name)
