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
