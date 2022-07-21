# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/
require 'json'
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_helper_methods'

# start the measure
class ResiliencyPAT < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    return "Resiliency PAT"
  end
  # human readable description
  def description
    return "This measure adds on-site generation and tariffs for running a parametric analysis for the Resiliency project"
  end
  # human readable description of modeling approach
  def modeler_description
    return "We modify the IDF for adding on-site generators (ICE and PV) and battery storage. 
ICE generators are defined in JSON files that store the generator type, the fuel resource, as well as power ratings and efficiency curves.
We also add tariffs depending on the climate zone (hence, the representative city).
Finally, we set up the SummaryReport to be in CSV format so that the post-processing tool can extract the electricity costs."
  end
  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # We generate the generator list from the available generator types
    chs = OpenStudio::StringVector.new
    # we fetch parameters from a JSON file in the resources directory
    gentypes = [
      'Diesel',
      'Gasoline',
      'NaturalGas',
      'PropaneGas'
    ]
    Dir.glob("#{__dir__}/resources/generators/*.json").each do |jsonfile|
      genjson = File.read(jsonfile)
      jsonhash = JSON.load(genjson)
      jsonhash.each do |genType, value|
        jsonhash[genType].each do |genRating, value|
          chs << "#{genType} - #{genRating}"
        end
      end
    end
    
    generator = OpenStudio::Measure::OSArgument::makeChoiceArgument("generator",chs)
    generator.setDisplayName("Generator rating")
    generator.setDescription("Electrical power output")
    generator.setDefaultValue("None - None")
    args << generator

    # Battery bank arguments
    batt_storage_capacity = OpenStudio::Measure::OSArgument.makeDoubleArgument('batt_storage_capacity', true)
    batt_storage_capacity.setDisplayName('Capacity of the battery bank')
    batt_storage_capacity.setDescription('Total capacity of the battery bank in kWh')
    args << batt_storage_capacity

    batt_discharge_power = OpenStudio::Measure::OSArgument.makeDoubleArgument('batt_discharge_power', true)
    batt_discharge_power.setDisplayName('Battery discharge power')
    batt_discharge_power.setDescription('Maximum discharge power in kW')
    args << batt_discharge_power

    batt_min_soc = OpenStudio::Measure::OSArgument.makeDoubleArgument('batt_min_soc', true)
    batt_min_soc.setDisplayName('Battery minimum SOC')
    batt_min_soc.setDescription('State of charge below which the generator will start charging the battery (0 - 1)')
    args << batt_min_soc

    batt_max_soc = OpenStudio::Measure::OSArgument.makeDoubleArgument('batt_max_soc', true)
    batt_max_soc.setDisplayName('Battery maximum SOC')
    batt_max_soc.setDescription('State of charge above which the generator will stop charging the battery (0 - 1)')
    args << batt_max_soc

    batt_initial_charge = OpenStudio::Measure::OSArgument.makeDoubleArgument('batt_initial_charge', true)
    batt_initial_charge.setDisplayName('Initial battery charge')
    batt_initial_charge.setDescription('Initial charge of the battery bank as a fraction of total capacity')
    args << batt_initial_charge

    pv_power = OpenStudio::Measure::OSArgument.makeDoubleArgument('pv_power', true)
    pv_power.setDisplayName('Solar panel output')
    pv_power.setDescription('Rated output for solar panels in kW')
    args << pv_power

    return args
  end

  def getGenHash()
    genhash = {}
    Dir.glob("#{__dir__}/resources/generators/*.json").each do |jsonfile|
      genjson = File.read(jsonfile)
      jsonhash = JSON.load(genjson)
      jsonhash.each do |genType, value|
        genhash[genType] = value
      end
    end
    return genhash
  end

  def getGenParams(gentypearg, genratingarg, genhash)

    genhash.each do |genType, value|
      if genType == gentypearg
        genhash[genType].each do |genRating, value|
          if genRating == genratingarg
            genparams = genhash[genType][genRating]
            return genparams
          end
        end
      end
    end
  end

  def getGenEPString(gentypearg, genratingarg, genhash)
    genparams = getGenParams(gentypearg, genratingarg, genhash)
    gen_nom_pow = genparams['NominalPower']
    genmaxeff = genparams['OptimumPLR']

    ices = [
      'Diesel',
      'Gasoline',
      'NaturalGas',
      'PropaneGas'
    ]

    genstrs = Array.new

    # Add ICE generator
    if ices.include? gentypearg 
    # Add a Diesel generator
      # Fetch HHV and fuel factors from JSON file
      fueljson = File.read("#{__dir__}/resources/fuelfactors.json")
      fuels = JSON.load(fueljson)
      hhv = fuels[gentypearg]['hhv']
      ffs = fuels[gentypearg]['ff']

      ice_string = "
      Generator:InternalCombustionEngine,
        fossilgen,                           !- Name
        #{gen_nom_pow},                                     !- Rated Power Output {W}
        Generator ICE Electric Node,   !- Electric Circuit Node Name
        0.0,                                       !- Minimum Part Load Ratio
        1.0,                                         !- Maximum Part Load Ratio
        #{genmaxeff},                                       !- Optimum Part Load Ratio
        Shaft Power Curve,       !- Shaft Power Curve Name
        ConstantQuadratic0,   !- Jacket Heat Recovery Curve Name
        ConstantQuadratic0,   !- Lube Heat Recovery Curve Name
        ConstantQuadratic150,   !- Total Exhaust Energy Curve Name
        ConstantQuadratic150,   !- Exhaust Temperature Curve Name
        0.00952329,                           !- Coefficient 1 of U-Factor Times Area Curve
        0.9,                                         !- Coefficient 2 of U-Factor Times Area Curve
        0.00000063,                           !- Maximum Exhaust Flow per Unit of Power Output {(kg/s)/W}
        0,                                         !- Design Minimum Exhaust Temperature {C}
        #{hhv},                                     !- Fuel Higher Heating Value {kJ/kg}
        0.0,                                         !- Design Heat Recovery Water Flow Rate {m3/s}
        ,                                               !- Heat Recovery Inlet Node Name
        ,                                               !- Heat Recovery Outlet Node Name
        #{gentypearg},                                   !- Fuel Type
        80; !- Heat Recovery Maximum Temperature
        "
      # here check curves needed for each gen type

      shaft_power = "
      Curve:Quadratic,
        Shaft Power Curve,       !- Name
        #{genparams['EfficiencyCurve'][0]},                                          !- Coefficient1 Constant
        #{genparams['EfficiencyCurve'][1]},                                           !- Coefficient2 x
        #{genparams['EfficiencyCurve'][2]},                                          !- Coefficient3 x**2
        0,                                           !- Minimum Value of x
        1,                                              !- Maximum Value of x
        0.0,                                           !- Minimum Curve Output
        0.4,                                           !- Maximum Curve Output
        Dimensionless,                                  !- Input Unit Type for X
        Dimensionless;                                  !- Output Unit Type
      "

      # We are not doing any thermal recovery for now, so assume flat curve for all exhaust-related curves. Assume 150C for all, even if it's too hot for lubricant and too cold for exhaust.
      constant_150 = "
      Curve:Quadratic,
        ConstantQuadratic150,       !- Name
        150,                                          !- Coefficient1 Constant
        0,                                           !- Coefficient2 x
        0,                                          !- Coefficient3 x**2
        0,                                           !- Minimum Value of x
        1,                                              !- Maximum Value of x
        0,                                           !- Minimum Curve Output
        1,                                           !- Maximum Curve Output
        Dimensionless,                                  !- Input Unit Type for X
        Dimensionless;                                  !- Output Unit Type
        "

      constant_0 = "
      Curve:Quadratic,
        ConstantQuadratic0,       !- Name
        0,                                          !- Coefficient1 Constant
        0,                                           !- Coefficient2 x
        0,                                          !- Coefficient3 x**2
        0,                                           !- Minimum Value of x
        1,                                              !- Maximum Value of x
        0,                                           !- Minimum Curve Output
        1,                                           !- Maximum Curve Output
        Dimensionless,                                  !- Input Unit Type for X
        Dimensionless;                                  !- Output Unit Type
        "

      gen_schedule_string = "
      Schedule:Constant,
        GEN_SCH,     !- Name
        On/Off,       !- Schedule Type Limits Name
        1.0;          !- Hourly Value
        "
      
      genstrs << shaft_power
      genstrs << constant_150
      genstrs << constant_0
      genstrs << ice_string
      genstrs << gen_schedule_string
    end

    return genstrs, gen_nom_pow, genmaxeff
  end

  def getPVEPString(pv_power)

    pv_power = pv_power * 1000
    pv_azimuth = 180 #Facing south
    pv_angle = 39 #Denver is at about 39 degrees latitude
    pv_density = 150
    pv_area = pv_power / pv_density
    pv_side_len = Math.sqrt(pv_area)

    panel_h = 1.6
    panel_w = 1
    total_panels = pv_area / (panel_h * panel_w)

    series_modules = total_panels #Assume all series for now
    parallel_modules = 1 
    pv_strings = Array.new

    surf_string = "
    Shading:Building,
      PV-surface,              !- Name
      #{pv_azimuth},                     !- Azimuth Angle {deg}
      #{pv_angle},                      !- Tilt Angle {deg}
      100,                      !- Starting X Coordinate {m}
      0,                       !- Starting Y Coordinate {m}
      0,                       !- Starting Z Coordinate {m}
      #{pv_side_len},                      !- Length {m}
      #{pv_side_len};                       !- Height {m}
    "
    pvperf_string = "
    PhotovoltaicPerformance:Simple,
      PV-performance,       !- Name
      0.90 ,                !- Fraction of Surface area that has active solar cells
      FIXED ,               !- Conversion efficiency input mode
      0.15 ,                !- Value for cell efficiency if fixed
      ;                     !- Name of Schedule that Defines Efficiency
    "

    pvgen_string = "
    Generator:Photovoltaic,
      PV-array,                                   !- Name
      PV-surface,                                 !- Surface Name
      PhotovoltaicPerformance:Simple,             !- Photovoltaic Performance Object Type
      PV-performance,                             !- Module Performance Name
      Decoupled,                                  !- Heat Transfer Integration Mode
      #{parallel_modules},                        !- Number of Series Strings in Parallel
      #{series_modules};                          !- Number of Modules in Series
    "
    pv_strings << surf_string
    pv_strings << pvperf_string
    pv_strings << pvgen_string

    return pv_strings
  end

  def getBattString(batt_storage_capacity, gen_nom_pow, pv_power, batt_initial_charge, batt_discharge_power)

    batt_storage_capacity = batt_storage_capacity * 3600000
    batt_charge_power = [gen_nom_pow, pv_power].max * 1.2

    # add a new battery object
    # Assume typical 80% round-trip efficiency (DC->storage->DC)
    batt_initial_charge = batt_initial_charge * batt_storage_capacity 
    batt_string = "
    ElectricLoadCenter:Storage:Simple,
      Battery,                               !- Name
      ALWAYS_ON,                             !- Availability Schedule Name
      ,                                      !- Zone Name
      0.0,                                   !- Radiative Fraction for Zone Heat Gains
      0.89,                                   !- Nominal Energetic Efficiency for Charging
      0.89,                                   !- Nominal Discharging Energetic Efficiency
      #{batt_storage_capacity},              !- Maximum Storage Capacity {J}
      #{batt_discharge_power*1000},               !- Maximum Power for Discharging {W}
      #{batt_charge_power},                  !- Maximum Power for Charging {W}
      #{batt_initial_charge};                                !- Initial State of Charge {J}
      "
    return batt_string, batt_charge_power
  end

  def getLoadCenterStrings(pv_power, gen_nom_pow, batt_storage_capacity, batt_charge_power, batt_discharge_power)
    loadcenterstrings = Array.new
    if pv_power > 0 and gen_nom_pow >0

      loadcenterstring = "
      ElectricLoadCenter:Generators,
        gen-list,                                           
        PV-array,
        Generator:Photovoltaic,
        #{pv_power},
        ALWAYS_ON,
        ,                               
        fossilgen,                                   
        Generator:InternalCombustionEngine,                     
        #{gen_nom_pow},                          
        GEN_SCH,                                           
        ;
        "

    elsif pv_power > 0 and gen_nom_pow == 0

      loadcenterstring = "
      ElectricLoadCenter:Generators,
        gen-list,                                           
        PV-array,
        Generator:Photovoltaic,
        #{pv_power},
        ALWAYS_ON,
        ;
        "
    
    elsif pv_power == 0 and gen_nom_pow > 0

      # add a new generator list object
      # Only contains the Diesel gen. I'm unsure why we need to specify the generator rated power again.
      loadcenterstring = "
      ElectricLoadCenter:Generators,
        gen-list,                                !- Name
        Diesel,                                   !- Generator 1 Name
        Generator:InternalCombustionEngine,                     !- Generator 1 Object Type
        #{gen_nom_pow},                          !- Generator 1 Rated Electric Power Output
        GEN_SCH,                                           !- Generator 1 Availability Schedule Name
        ;                                           !- Generator 1 Rated Thermal to Electrical Power Ratio
        "
    else
      loadcenterstring = nil
    end

    loadcenterstrings << loadcenterstring

    if batt_storage_capacity > 0
      inverter_string = "
        ElectricLoadCenter:Inverter:Simple,
          Simple Ideal Inverter,                  !- Name
          Always On,                              !- Availability Schedule Name
          ,                                       !- Zone Name
          0.0,                                    !- Radiative Fraction
          0.95;                                    !- Inverter Efficiency
          "
      loadcenterstrings << inverter_string

      # add a new inverter object
      # Let's assume it isn't great and has 90% efficiency
      converter_string = "
      ElectricLoadCenter:Storage:Converter,
        Simple Converter , !- Name
        ALWAYS_ON , !- Availability Schedule Name
        SimpleFixed , !- Power Conversion Efficiency Method
        0.9 , !- Simple Fixed Efficiency
        , !- Design Maximum Continuous Input Power
        , !- Efficiency Function of Power Curve Name 20
        , !- Ancillary Power Consumed In Standby
        , !- Zone Name 
        0.25; !- Radiative Fraction
        "
      loadcenterstrings << converter_string

      # add a new electric load center distributor
      # we need one distributor per generator if we mix AC and DC.
      electric_distributor_string = "
      ElectricLoadCenter:Distribution,
        On-site generation,      !- Name
        gen-list,                            !- Generator List Name
        TrackSchedule,                        !- Generator Operation Scheme Type
        0.0,                                    !- Demand Limit Scheme Purchased Electric Demand Limit {W}
        GEN_SCH,                                       !- Track Schedule Name Scheme Schedule Name
        ,                                       !- Track Meter Scheme Meter Name
        DirectCurrentWithInverterDCStorage,     !- Electrical Buss Type
        Simple Ideal Inverter,                  !- Inverter Object Name
        Battery,                                !- Electrical Storage Object Name
        ,
        TrackFacilityElectricDemandStoreExcessOnSite,
        ,                  !- Storage control track meter
        , !- Storage converter
        ,                 !- Max SOC
        ,              !- Min SOC
        #{batt_charge_power},                 !- Design charge power
        ,                 !- Charge schedule
        #{batt_discharge_power*1000},                 !- discharge power
        ,                 !- discharge schedule
        ,                 !- Utility demand target
        ,                 !- Utility demand target schedule
        ;
        "

    else
      electric_distributor_string = "
      ElectricLoadCenter:Distribution,
        On-site diesel generation,      !- Name
        gen-list,                            !- Generator List Name
        TrackElectrical,                        !- Generator Operation Scheme Type
        0.0,                                    !- Demand Limit Scheme Purchased Electric Demand Limit {W}
        GEN_SCH,                                       !- Track Schedule Name Scheme Schedule Name
        ,                                       !- Track Meter Scheme Meter Name
        AlternatingCurrent;
        "

    end

    loadcenterstrings << electric_distributor_string
    
    return loadcenterstrings
  end

  def getFuelFactors(gentypearg)
    fueljson = File.read("#{__dir__}/resources/fuelfactors.json")
    fuels = JSON.load(fueljson)
    hhv = fuels[gentypearg]['hhv']
    ffs = fuels[gentypearg]['ff']
    unit = fuels[gentypearg]['unit']

    fuelfactor_string = "
      FuelFactors,          !  USA national average based on eGRID, EIA 1605
        #{gentypearg},        !- Existing Fuel Resource Name
        #{unit},                 !- Units of Measure (kg or m3)
        #{hhv},                   !- Energy per Unit Factor
        1,              !- Source Energy Factor {J/J}
        ,                   !- Source Energy Schedule Name
        #{ffs['co2']},          !- CO2 Emission Factor {g/MJ}
        ,                   !- CO2 Emission Factor Schedule Name
        #{ffs['co']},        !- CO Emission Factor {g/MJ}
        ,                   !- CO Emission Factor Schedule Name
        #{ffs['ch4']},        !- CH4 Emission Factor {g/MJ}
        ,                   !- CH4 Emission Factor Schedule Name
        #{ffs['nox']},        !- NOx Emission Factor {g/MJ}
        ,                   !- NOx Emission Factor Schedule Name
        #{ffs['n2o']},        !- N2O Emission Factor {g/MJ}
        ,                   !- N2O Emission Factor Schedule Name
        #{ffs['so2']},        !- SO2 Emission Factor {g/MJ}
        ,                   !- SO2 Emission Factor Schedule Name
        #{ffs['pm']},        !- PM Emission Factor {g/MJ}
        ,                   !- PM Emission Factor Schedule Name
        #{ffs['pm10']},        !- PM10 Emission Factor {g/MJ}
        ,                   !- PM10 Emission Factor Schedule Name
        #{ffs['pm2.5']},        !- PM2.5 Emission Factor {g/MJ}
        ,                   !- PM2.5 Emission Factor Schedule Name
        #{ffs['nh3']},        !- NH3 Emission Factor {g/MJ}
        ,                   !- NH3 Emission Factor Schedule Name
        #{ffs['nmvoc']},        !- NMVOC Emission Factor {g/MJ}
        ,                   !- NMVOC Emission Factor Schedule Name
        #{ffs['hg']},        !- Hg Emission Factor {g/MJ}
        ,                   !- Hg Emission Factor Schedule Name
        #{ffs['pb']},                  !- Pb Emission Factor {g/MJ}
        ,                   !- Pb Emission Factor Schedule Name
        0,            !- Water Emission Factor {L/MJ}
        ,                   !- Water Emission Factor Schedule Name
        0,                  !- Nuclear High Level Emission Factor {g/MJ}
        ,                   !- Nuclear High Level Emission Factor Schedule Name
        0;                  !- Nuclear Low Level Emission Factor {m3/MJ}                      
        "
    return fuelfactor_string
  end

  def getEMSStrings(batt_min_soc, batt_storage_capacity, gen_nom_pow, maxeff, batt_max_soc)
    emsstrs = Array.new
    # add a new EMS Sensor object
    ems_sensor_string = "
    EnergyManagementSystem:Sensor,
      BattCharge, !- Name
      Battery , !- Output:Variable or Output:Meter Index Key Name
      Electric Storage Simple Charge State ; !- Output:Variable or Output:Meter Name
      "
    emsstrs << ems_sensor_string

    # add a new EMS Actuator object
    ems_actuator_string = "
    EnergyManagementSystem:Actuator,
      gen_SCH_override,               !- Name
      GEN_SCH,                          !- Actuated Component Unique Name
      Schedule:Constant,                    !- Actuated Component Type
      Schedule Value;                       !- Actuated Component Control Type
      "
    emsstrs << ems_actuator_string

    # add a new EMS Actuator object for setting generator output
    ems_actuator_string = "
    EnergyManagementSystem:Actuator,
      gen_out,               !- Name
      fossilgen,                          !- Actuated Component Unique Name
      On-Site Generator Control,                    !- Actuated Component Type
      Requested Power;                       !- Actuated Component Control Type
      "
    emsstrs << ems_actuator_string

    # add a new EMS program object
    ems_program_string = "
    EnergyManagementSystem:Program,
      CheckBatteryStateOfCharge ,     !- Name
      IF BattCharge < (#{batt_min_soc} * #{batt_storage_capacity}),
        SET gen_sch_override = 1.0 ,  
        SET gen_out = #{gen_nom_pow} * #{maxeff} ,
      ELSEIF BattCharge >= (#{batt_max_soc} * #{batt_storage_capacity}),
        SET gen_sch_override = 0.0 ,  
        SET gen_out = 0.0 ,
      ENDIF;
      "
    emsstrs << ems_program_string

    # add a new EMS program calling manager object
    ems_program_calling_string = "
    EnergyManagementSystem:ProgramCallingManager,
      Battery Charging Control , !- Name
      EndOfZoneTimestepAfterZoneReporting ,    !- EnergyPlus Model Calling Point
      CheckBatteryStateOfCharge;         !- Program Name 1
      "
    emsstrs << ems_program_calling_string
    return emsstrs
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # assign the user inputs to variables
    batt_storage_capacity = runner.getDoubleArgumentValue('batt_storage_capacity', user_arguments)
    batt_discharge_power = runner.getDoubleArgumentValue('batt_discharge_power', user_arguments)
    batt_min_soc = runner.getDoubleArgumentValue('batt_min_soc', user_arguments)
    batt_max_soc = runner.getDoubleArgumentValue('batt_max_soc', user_arguments)
    batt_initial_charge = runner.getDoubleArgumentValue('batt_initial_charge', user_arguments)
    generator = runner.getStringArgumentValue('generator', user_arguments)
    pv_power = runner.getDoubleArgumentValue('pv_power', user_arguments)

    # Retrieve generator type and rating from generator argument
    genselect = generator.split(" - ")
    gentypearg = genselect[0]
    genratingarg = genselect[1]
    genhash = getGenHash()
    
    # Add PV if any
    pvstrings = getPVEPString(pv_power)
    if pv_power > 0
      
      pvstrings.each do |string|
        idfObject = OpenStudio::IdfObject.load(string)
        object = idfObject.get
        wsObject = workspace.addObject(object)
      end

    end

    # add a new diesel generator object with quadratic curves
    genstrings, genpow, maxeff = getGenEPString(gentypearg, genratingarg, genhash)

    # Add batteries
    battstr, batt_charge_power = getBattString(batt_storage_capacity, genpow, pv_power, batt_initial_charge, batt_discharge_power)
    idfObject = OpenStudio::IdfObject.load(battstr)
    object = idfObject.get
    wsObject = workspace.addObject(object)
    
    if genpow > 0
      #First, the performance curves
      genstrings.each do |obj|
        idfObject = OpenStudio::IdfObject.load(obj)
        object = idfObject.get
        wsObject = workspace.addObject(object)
      end

    end
    
    elecstrs = getLoadCenterStrings(pv_power, genpow, batt_storage_capacity, batt_charge_power, batt_discharge_power)
    elecstrs.each do |elec|
      if elec != nil
        idfObject = OpenStudio::IdfObject.load(elec)
        object = idfObject.get
        wsObject = workspace.addObject(object)
      end
    end

    if genpow > 0
      ffstrs = getFuelFactors(gentypearg)
      idfObject = OpenStudio::IdfObject.load(ffstrs)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      
      emsstrs = getEMSStrings(batt_min_soc, batt_storage_capacity, genpow, maxeff, batt_max_soc)
      emsstrs.each do |emsstr|
        idfObject = OpenStudio::IdfObject.load(emsstr)
        object = idfObject.get
        wsObject = workspace.addObject(object)
      end
    end



    env_factors_string = "
    EnvironmentalImpactFactors,
      0.3,         !- Disctrict Heating Efficiency
      3.0,         !- District Cooling COP
      0.25,        !- Steam Conversion Efficiency
      80.7272,     !- Total Carbon Equivalent Emission Factor From N2O
      6.2727,      !- Total Carbon Equivalent Emission Factor From CH4
      0.2727;      !- Total Carbon Equivalent Emission Factor From CO2
    
    "
    idfObject = OpenStudio::IdfObject.load(env_factors_string)
    object = idfObject.get
    wsObject = workspace.addObject(object)
    envfactors = wsObject.get

    env_out_string = "
    Output:EnvironmentalImpactFactors,
      Monthly;  !- Reporting_Frequency
    "
    idfObject = OpenStudio::IdfObject.load(env_out_string)
    object = idfObject.get
    wsObject = workspace.addObject(object)
    envfactorsout = wsObject.get

    fuelfactor_string = "
      FuelFactors,          !  USA national average based on eGRID, EIA 1605
        Electricity,        !- Existing Fuel Resource Name
        kg,                 !- Units of Measure (kg or m3)
        ,                   !- Energy per Unit Factor
        3.101,              !- Source Energy Factor {J/J}
        ,                   !- Source Energy Schedule Name
        242.67191,          !- CO2 Emission Factor {g/MJ}
        ,                   !- CO2 Emission Factor Schedule Name
        1.51E03,        !- CO Emission Factor {g/MJ}
        ,                   !- CO Emission Factor Schedule Name
        1.60E-03,        !- CH4 Emission Factor {g/MJ}
        ,                   !- CH4 Emission Factor Schedule Name
        4.74E-01,        !- NOx Emission Factor {g/MJ}
        ,                   !- NOx Emission Factor Schedule Name
        3.64E-03,        !- N2O Emission Factor {g/MJ}
        ,                   !- N2O Emission Factor Schedule Name
        1.25E-01,        !- SO2 Emission Factor {g/MJ}
        ,                   !- SO2 Emission Factor Schedule Name
        0,        !- PM Emission Factor {g/MJ}
        ,                   !- PM Emission Factor Schedule Name
        5.84E-01,        !- PM10 Emission Factor {g/MJ}
        ,                   !- PM10 Emission Factor Schedule Name
        0.0,        !- PM2.5 Emission Factor {g/MJ}
        ,                   !- PM2.5 Emission Factor Schedule Name
        0.0,        !- NH3 Emission Factor {g/MJ}
        ,                   !- NH3 Emission Factor Schedule Name
        0.0,        !- NMVOC Emission Factor {g/MJ}
        ,                   !- NMVOC Emission Factor Schedule Name
        0.0,        !- Hg Emission Factor {g/MJ}
        ,                   !- Hg Emission Factor Schedule Name
        0,                  !- Pb Emission Factor {g/MJ}
        ,                   !- Pb Emission Factor Schedule Name
        0.0,            !- Water Emission Factor {L/MJ}
        ,                   !- Water Emission Factor Schedule Name
        0,                  !- Nuclear High Level Emission Factor {g/MJ}
        ,                   !- Nuclear High Level Emission Factor Schedule Name
        0;                  !- Nuclear Low Level Emission Factor {m3/MJ}                      
        "
      idfObject = OpenStudio::IdfObject.load(fuelfactor_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      fuelfactors = wsObject.get

    return true
  end
end

# register the measure to be used by the application
ResiliencyPAT.new.registerWithApplication
