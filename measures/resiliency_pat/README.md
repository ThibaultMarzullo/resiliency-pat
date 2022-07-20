

###### (Automatically generated documentation)

# Resiliency PAT

## Description
This measure adds on-site generation and tariffs for running a parametric analysis for the Resiliency project

## Modeler Description
We modify the IDF for adding on-site generators (ICE and PV) and battery storage. 
ICE generators are defined in JSON files that store the generator type, the fuel resource, as well as power ratings and efficiency curves.
We also add tariffs depending on the climate zone (hence, the representative city).
Finally, we set up the SummaryReport to be in CSV format so that the post-processing tool can extract the electricity costs.

## Measure Type
EnergyPlusMeasure

## Taxonomy


## Arguments


### Capacity of the battery bank
Total capacity of the battery bank in kWh
**Name:** batt_storage_capacity,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Battery discharge power
Maximum discharge power in kW
**Name:** batt_discharge_power,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Battery minimum SOC
State of charge below which the generator will start charging the battery (0 - 1)
**Name:** batt_min_soc,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Battery maximum SOC
State of charge above which the generator will stop charging the battery (0 - 1)
**Name:** batt_max_soc,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Initial battery charge
Initial charge of the battery bank as a fraction of total capacity
**Name:** batt_initial_charge,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Diesel generator rating
Electrical power output
**Name:** generator,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "3.2kW Diesel", "8kW Diesel", "10kW Diesel", "12.5kW Diesel", "20kW Diesel", "32kW Diesel", "42kW Diesel", "55kW Diesel", "80kW Diesel", "113kW Diesel"]


### Solar panel output
Rated output for solar panels in kW
**Name:** pv_power,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false






