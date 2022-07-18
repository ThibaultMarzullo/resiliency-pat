from utilities import ImportResources, CreateDirsAndOutputs
import os

def testUtilities():

    weapath_in = os.normpath(os.path.join(os.path.dirname(__file__), "..", "input", "weather", "USA_CO_Denver-Aurora-Buckley.AFB.724695_TMY3.epw"))
    idfpath_in = os.normpath(os.path.join(os.path.dirname(__file__), "..", "input", "idf", "ASHRAE901_OfficeSmall_STD2016_Denver.idf"))
    

    try:
        weapath, idfpath = ImportResources().findPaths()
        if weapath != weapath_in:
            print(f"Failed: Weather file path should be {weapath_in}, it is {weapath}")
        if idfpath != idfpath_in:
            print(f"Failed: IDF path should be {idfpath_in}, it is {idfpath}")
        if idfpath == idfpath_in and weapath == weapath_in:
            print("Success: ImportResources")
    except:
        print("Failed: ImportResources.")

    
        
        