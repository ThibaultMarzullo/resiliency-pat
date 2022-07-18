import pandas as pd
import numpy as np
import os, shutil, json, zipfile

class ResultsParser():

    def __init__(self, csvpath, paramvars) -> None:
        
        self.patResultsDir = os.path.join(os.path.dirname(os.path.realpath(csvpath)), 'localResults')
        self.summary = pd.read_csv(csvpath)
        self.resultsDir = os.path.join(os.path.realpath(os.path.dirname(os.path.dirname(__file__))), 'output')
        self.postProcessDir = os.path.join(self.resultsDir, 'post-processed')
        self.paramvars = paramvars
        self.rawDir = os.path.join(self.resultsDir, 'raw')
        self.copyRawResults()
        #self.importHashes(csvpath)
        
    def copyRawResults(self):

        for index, row in self.summary.iterrows():
            rawdir = self.copyDir(row["_id"])
            postdir = os.path.join(self.postProcessDir, row["_id"])
            if rawdir is not None:
                parameters = {}
                self.fetchCSVs(rawdir, row["_id"])
                for p in self.paramvars:
                    parameters[p] = row[p]
                with open(os.path.join(postdir, 'params.json'), 'w') as f:
                    json.dump(parameters, f)

    def fetchCSVs(self, dirname, simid):
        # the results are zipped in data_point.zip
        datapointzip = os.path.join(dirname, 'data_point.zip')
        extractdir = os.path.join(dirname, 'extracted')
        os.mkdir(extractdir)
        with zipfile.ZipFile(datapointzip, 'r') as zip_ref:
            zip_ref.extractall(extractdir)

        subfolders = [ f.path for f in os.scandir(extractdir) if f.is_dir() ]
        df = pd.DataFrame()
        for folder in subfolders:
            allfiles = os.listdir(folder)    
            csvfiles = list(filter(lambda f: f.endswith('.csv'), allfiles))
            for csvfile in csvfiles:
                csvdf = pd.read_csv(os.path.join(folder, csvfile))
                csvdf['Zone Timestep'] = pd.to_datetime(csvdf['Zone Timestep'], format='%Y-%b-%d %H:%M:%S')
                csvdf.set_index('Zone Timestep', inplace=True)
                if df.empty:
                    df = csvdf
                else:
                    df = pd.concat([df, csvdf], axis=1)
        postprocessdir = os.path.join(self.postProcessDir, simid)
        df.to_csv(os.path.join(postprocessdir, 'concatenated.csv'))


    def copyDir(self, dirname):
        rawdir = os.path.join(self.rawDir, dirname)
        origdir = os.path.join(self.patResultsDir, dirname)
        postprocessdir = os.path.join(self.postProcessDir, dirname)
        if os.path.exists(origdir):
            if os.path.isdir(rawdir):
                shutil.rmtree(rawdir)   
            if os.path.isdir(postprocessdir):
                shutil.rmtree(postprocessdir) 
            os.makedirs(postprocessdir)
            shutil.copytree(origdir, rawdir)

            return rawdir
        else:
            return None
            


