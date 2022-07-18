from utilities import ImportResources, CreateDirsAndOutputs
from parsing import ResultsParser
import os

csvpath = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'input', 'patresults', 'resiliency_pat.csv')
paramvars = [
    'add_diesel_generator_one_distribution_center.batt_storage_capacity',
    'add_diesel_generator_one_distribution_center.generator',
    'add_diesel_generator_one_distribution_center.pv_power',
    'create_doe_prototype_building.building_type',
    'create_doe_prototype_building.climate_zone',
]
ResultsParser(csvpath, paramvars)

#def testUtilities():

#    weapath_in = os.normpath(os.path.join(os.path.dirname(__file__), "..", "input", "weather", "USA_CO_Denver-Aurora-Buckley.AFB.724695_TMY3.epw"))
#    idfpath_in = os.normpath(os.path.join(os.path.dirname(__file__), "..", "input", "idf", "ASHRAE901_OfficeSmall_STD2016_Denver.idf"))
    

#    try:
#        weapath, idfpath = ImportResources().findPaths()
#        if weapath != weapath_in:
#            print(f"Failed: Weather file path should be {weapath_in}, it is {weapath}")
#        if idfpath != idfpath_in:
#            print(f"Failed: IDF path should be {idfpath_in}, it is {idfpath}")
#        if idfpath == idfpath_in and weapath == weapath_in:
#            print("Success: ImportResources")
#    except:
#        print("Failed: ImportResources.")
#
    
        
        