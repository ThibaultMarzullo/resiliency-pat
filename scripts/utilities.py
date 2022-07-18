import glob
import os
import json
import hashlib
import shutil
import datetime
import openstudio

class ImportResources():

    '''
    Helper for finding the paths to an IDF and the matching weather file.
    '''

    def __init__(self, verbose = 3):
        self.verbose = verbose

    def findPaths(self, location='Denver', building='OfficeSmall', standard='ASHRAE 90.1', year=2016):
        if self.verbose > 1:
            print(f"Loading {building} building model: {standard} {year}, located in {location}")
        epwpath = self.searchEPW(location=location)
        idfpath = self.searchIDF(building=building, standard=standard, year=year, location=location)

        return epwpath, idfpath

    def searchEPW(self, location):
        '''
        Search for the weather file matching a given location.

        Parameters
        ----------
        location : str
            Representative city for a climate zone. Must be one of: Honolulu, New Delhi, Tampa, Tucson, 
            Atlanta, El Paso, San Diego, New York, Albuquerque, Seattle, Buffalo, Denver, Port Angeles, 
            Rochester, Great Falls, International Falls, Fairbanks

        Returns
        -------
        str
            Path to the .epw file corresponding to the requested location.
        '''

        location = location.replace(" ", ".")
        searchdir = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "input", "weather"))
        files = glob.glob(os.path.join(searchdir, f"*{location}*.epw"))
        assert[files!=[], f"Could not find the {location} weather file, or found more than one."]
        if self.verbose > 1:
            print(f"Found weather file: {files[0]}")
        return files[0]

    def searchIDF(self, building, standard, year, location):
        '''
        Search for the IDF file matching a building type, standard and year.

        Parameters
        ----------
        building : str
            Building type. Must be one of the DOE Prototype building types
        standard : str
            Building standard used to generate the prototype building. Must be one of ASHRAE 90.1 or IECC.
        year : int
            Year the standard was published. For ASHRAE 90.1, must be one of 2013, 2016 or 2019. For IECC, 
            must be one of 2012, 2015 or 2018.
        location : str
            Loaction of the building. Must be one of Honolulu, New Delhi, Tampa, Tucson, Atlanta, El Paso, 
            San Diego, New York, Albuquerque, Seattle, Buffalo, Denver, Port Angeles, Rochester, Great Falls, 
            International Falls, Fairbanks

        Returns
        -------
        str
            Path to the .idf file corresponding to the requested building.
        '''

        standard = standard.replace(" ", "").replace(".", "")
        searchdir = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "input", "idf"))
        files = glob.glob(os.path.join(searchdir, f"{standard}*{building}*{year}*{location}*.idf"))
        assert[files!=[], f"Could not find the idf file."]
        if self.verbose > 1:
            print(f"Found idf file: {files[0]}")
        return files[0]

class CreateDirsAndOutputs():

    '''
    Find existing output directories, clean up simulation results or create new directories
    '''

    def __init__(self, verbose = 3) -> None:

        self.verbose = verbose
        self.searchdir = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "output", "raw"))
        
    def findOrCreateDirs(self, input):
        casedir = self.findExistingDirs(input)
        
        if casedir is not None:
            self.cleanupDir(casedir)
            simdir = casedir
        else:
            simdir = self.createDir(input)

        return simdir

    def findExistingDirs(self, input):
        
        '''
        Finds directories that contain simulation results identical to those being requested by 
        comparing the MD5 hashe of the desired input JSON file to those of existing simulation results.

        Parameters
        ----------
        input : json
            JSON file containing the simulation parameters

        Returns:
        --------
        str or None
            If an existing simulation is found, the function returns the path. Otherwise, it returns None.
        '''
        
        casedir = None
        inputhash = hashlib.md5(json.dumps(input).encode("utf-8")).hexdigest()

        for dir in os.listdir(self.searchdir):
            jsonpath = os.path.join(self.searchdir, dir, "input.json")
            if os.path.exists(jsonpath):
                casejson = json.load(open(jsonpath))
                casehash = hashlib.md5(json.dumps(casejson).encode("utf-8")).hexdigest()
                if casehash == inputhash:
                    casedir = os.path.join(self.searchdir, dir)

        return casedir

    def cleanupDir(self, casedir):

        '''
        Erase existing simulation results.

        Parameters
        ----------
        casedir : str
            Path to the simulation results directory.

        '''

        if self.verbose > 1:
            print(f"Found existing output directory for this input configuration: {casedir}\nThe existing results will be overridden.")
        for f in os.listdir(casedir):
            if f != 'input.json':
                os.remove(os.path.join(casedir, f))

    def createDir(self, input):

        '''
        Creates a new directory for storing simulation results.

        Returns
        ----------
        str
            Path to the simulation results directory.
        '''

        if self.verbose > 1:
            print("Did not find a directory with results from the same input configuration. A new directory will be created.")
        dir = os.path.join(self.searchdir, datetime.date.today().strftime("%Y-%m-%d"))
        os.makedirs(dir)
        with open(os.path.join(dir, 'input.json'), 'w') as f:
            json.dump(input, f)
        
        return dir

class CreateOSWs():

    def __init__(self) -> None:
        pass

    def getWeatherFile(self, location):
        return ImportResources.searchEPW(location)

    def getOutputDir(self, workflow):
        dirs = CreateDirsAndOutputs()
        return dirs.findOrCreateDirs(workflow)

    def createOSW(self, building='SmallOffice', standard='90.1', year='2016', climatezone='3A'):
        #epwpath = self.getWeatherFile(location)
        workflow = {
        "steps": [
            {
            "measure_dir_name": "CreateDOEPrototypeBuilding",
            "arguments": {
                "building_type" : building,
                "template" : f"{standard}-{year}",
                "climate_zone" : f"ASHRAE 169-2013-{climatezone}"
            }
            },
        ]
        }

        with open(os.path.join(self.getOutputDir(workflow), 'input.json'), 'w') as f:
            json.dump(workflow, f)

        #workflow = openstudio.openstudioutilitiescore.


class CreatePrototypeBuilding():

    def __init__(self) -> None:
        model = openstudio.model.Model()

        
    def findProtoMeasure(self):
        '''
        Find the BCL measure for creating DOE prototype buildings in the measures directory.
        
        Returns
        -------
        openstudio.BCLMeasure
            BCLMeasure object
        '''
        measuresdir = os.path.realpath(os.path.join(__file__, '..', '..', 'measures'))
        protobldgmeas = None
        for meas in openstudio.BCLMeasure_getMeasuresInDir(measuresdir):
            if meas.name() == 'create_doe_prototype_building':
                protobldgmeas = meas
        assert[protobldgmeas is not None, f"Error: could not find a measure for creating DOE prototype buildings in the {measuresdir} directory.\nPlease download the measure from BCL and try again."]

        return protobldgmeas

    #def applyMeasure(self, model):



#debug, debugs = ImportResources().findPaths()

input = {
    'var' : 'one',
    'foo' : 'bar'
}

#debug = CreateDirsAndOutputs().findOrCreateDirs(input)
#debug = CreatePrototypeBuilding()
debug = CreateOSWs()
debug.createOSW()