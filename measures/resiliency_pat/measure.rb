# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/
require JSON

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
    chs << "None"
    # we fetch parameters from a JSON file in the GeneratorData directory
    Dir.glob('./GeneratorData/*.json') do |jsonfile|
      genjson = File.read(jsonfile)
      jsonhash = JSON.parse(genjson)
      jsonhash.each do |genType, value|
        jsonhash[genType].each do |genRating, value|
          chs << "#{genType} - #{genRating}"
        end
      end
    end
    
    generator = OpenStudio::Measure::OSArgument::makeChoiceArgument("generator",chs)
    generator.setDisplayName("Diesel generator rating")
    generator.setDescription("Electrical power output")
    generator.setDefaultValue("None")
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

  def getGenParams(gentypearg, genratingarg)

    Dir.glob('./GeneratorData/*.json') do |jsonfile|
      genjson = File.read(jsonfile)
      jsonhash = JSON.parse(genjson)
      jsonhash.each do |genType, value|
        if genType == gentypearg
          jsonhash[genType].each do |genRating, value|
            if genRating == genratingarg
              genparams = jsonhash[genType][genRating]
              return genparams
            end
          end
        end
      end
    end
  end

  def getGenEPString(gentypearg, genratingarg)
    genparams = getGenParams(gentypearg, genratingarg)

    ICEs = [
      'Diesel',
      'Gasoline',
      'NaturalGas',
      'PropaneGas'
    ]

    case gentypearg
    when 'NaturalGas'
      hhv = 45357
      fuelfactors = {
        'co2' : 50.23439,
        'co' : 0.0351641,
        'ch4' : 0.000962826,
        'nox' : 0.0418620,
        'n2o' : 0.000920964,
        'so2' : 0.000251172,
        'pm' : 0.00318151,
        'pm10' : 0.00238613,
        'pm2.5' : 0.000795378,
        'nh3' : 0,
        'nmvoc' : 0.00230241,
        'hg' : 0.000000108841,
        'pb' : 0.000000209310
      }
    when 'PropaneGas'
      hhv = 46134
      fuelfactors = {
        'co2' : 68.47995,
        'co' : 0.0154,
        'ch4' : 0.000663,
        'nox' : 0.0737,
        'n2o' : 0.000338,
        'so2' : 0.482,
        'pm' : 0.00614,
        'pm10' : 0.00332,
        'pm2.5' : 0.00255,
        'nh3' : 0,
        'nmvoc' : 0.00104,
        'hg' : 0.00000347,
        'pb' : 0.00000464
      }
    when 'Diesel'
      hhv = 45500
      fuelfactors = {
        'co2' : 70.50731,
        'co' : 0.408,
        'ch4' : 0,
        'nox' : 1.9,
        'n2o' :0,
        'so2' : 0.125,
        'pm' : 0,
        'pm10' : 0.133,
        'pm2.5' : 0,
        'nh3' : 0,
        'nmvoc' : 0.15,
        'hg' : 0,
        'pb' : 0
      }
    when 'Gasoline'
      hhv = 45500
      fuelfactors = {
        'co2' : 68.20808,
        'co' : 27,
        'ch4' : 0,
        'nox' : 0.701,
        'n2o' : 0,
        'so2' : 0.0361,
        'pm' : 0,
        'pm10' : 0.043,
        'pm2.5' : 0,
        'nh3' : 0,
        'nmvoc' : 0.903,
        'hg' : 0,
        'pb' : 0
      }

    if ICEs.include? gentypearg 
    # Add a Diesel generator
      ice_string = "
      Generator:InternalCombustionEngine,
        fossilgen,                           !- Name
        #{genparams['NominalPower']},                                     !- Rated Power Output {W}
        Generator ICE Electric Node,   !- Electric Circuit Node Name
        0.0,                                       !- Minimum Part Load Ratio
        1.0,                                         !- Maximum Part Load Ratio
        #{genparams['OptimumPLR']},                                       !- Optimum Part Load Ratio
        Shaft Power Curve,       !- Shaft Power Curve Name
        ConstantQuadratic0,   !- Jacket Heat Recovery Curve Name
        ConstantQuadratic0,   !- Lube Heat Recovery Curve Name
        ConstantQuadratic150,   !- Total Exhaust Energy Curve Name
        ConstantQuadratic150,   !- Exhaust Temperature Curve Name
        0.00952329,                           !- Coefficient 1 of U-Factor Times Area Curve
        0.9,                                         !- Coefficient 2 of U-Factor Times Area Curve
        0.00000063,                           !- Maximum Exhaust Flow per Unit of Power Output {(kg/s)/W}
        0,                                         !- Design Minimum Exhaust Temperature {C}
        45500,                                     !- Fuel Higher Heating Value {kJ/kg}
        0.0,                                         !- Design Heat Recovery Water Flow Rate {m3/s}
        ,                                               !- Heat Recovery Inlet Node Name
        ,                                               !- Heat Recovery Outlet Node Name
        Diesel,                                   !- Fuel Type
        80; !- Heat Recovery Maximum Temperature
        "

    curves = Array.new

    # here check curves needed for each gen type

    shaft_power = "
    Curve:Quadratic,
      BG Shaft Power Curve,       !- Name
      #{c},                                          !- Coefficient1 Constant
      #{x},                                           !- Coefficient2 x
      #{x2},                                          !- Coefficient3 x**2
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

      curves << shaft_power
      curves << constant_150
      curves << constant_0
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
    genselect = generator.split(' - ')
    gentypearg = genselect[0]
    genratingarg = genselect[1]

    # Find the corresponding generator in the JSON files and generate EP strings for the generator, its 
    # power and efficiency curves, its name for later use and its schedule
    genstring, curves, genname, gensched = getGenEPString(gentypearg, genratingarg)



    if pv_power > 0
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

      new_pv_surface_string = "
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
      idfObject = OpenStudio::IdfObject.load(new_pv_surface_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_pv_surface = wsObject.get

      

      # add a new PV performance object. Assume square wafers with 90% packing density, 15% efficiency
      new_pv_performance_string = "
      PhotovoltaicPerformance:Simple,
        PV-performance,       !- Name
        0.90 ,                !- Fraction of Surface area that has active solar cells
        FIXED ,               !- Conversion efficiency input mode
        0.15 ,                !- Value for cell efficiency if fixed
        ;                     !- Name of Schedule that Defines Efficiency
        "
      idfObject = OpenStudio::IdfObject.load(new_pv_performance_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_pv_performance = wsObject.get

      # add a new PV generator object
      new_pv_generator_string = "
      Generator:Photovoltaic,
        PV-array,                                   !- Name
        PV-surface,                                 !- Surface Name
        PhotovoltaicPerformance:Simple,             !- Photovoltaic Performance Object Type
        PV-performance,                             !- Module Performance Name
        Decoupled,                                  !- Heat Transfer Integration Mode
        #{parallel_modules},                        !- Number of Series Strings in Parallel
        #{series_modules};                          !- Number of Modules in Series
        "
      idfObject = OpenStudio::IdfObject.load(new_pv_generator_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_pv_generator = wsObject.get

    end

    batt_storage_capacity = batt_storage_capacity * 3600000
    batt_charge_power = [gen_nom_pow, pv_power].max * 1.2

    # add a new battery object
    # Assume typical 80% round-trip efficiency (DC->storage->DC)
    batt_initial_charge = batt_initial_charge * batt_storage_capacity 
    new_battery_string = "
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
    idfObject = OpenStudio::IdfObject.load(new_battery_string)
    object = idfObject.get
    wsObject = workspace.addObject(object)
    new_battery = wsObject.get


    # add a new diesel generator object with quadratic curves

    
    idfObject = OpenStudio::IdfObject.load(new_constquadcurve_string)
    object = idfObject.get
    wsObject = workspace.addObject(object)
    new_constquadcurve = wsObject.get
    
    
    idfObject = OpenStudio::IdfObject.load(new_diesel_generator_string)
    object = idfObject.get
    wsObject = workspace.addObject(object)
    new_diesel_generator = wsObject.get

    # add a new Schedule object
    # Will be used to manage the generator operation. If used alone with TrackSchedule operation, will only operate generator at the lowest PLR.
    new_gen_schedule_string = "
    Schedule:Constant,
      GEN_SCH,     !- Name
      On/Off,       !- Schedule Type Limits Name
      1.0;          !- Hourly Value
      "
    idfObject = OpenStudio::IdfObject.load(new_gen_schedule_string)
    object = idfObject.get
    wsObject = workspace.addObject(object)
    new_gen_schedule = wsObject.get

    if pv_power > 0 and gen_nom_pow >0

      # add a new generator list object
      # Diesel + solar gen. I'm unsure why we need to specify the generator rated power again.
      new_generator_list_string = "
      ElectricLoadCenter:Generators,
        gen-list,                                           
        PV-array,
        Generator:Photovoltaic,
        #{pv_power},
        ALWAYS_ON,
        ,                               
        Diesel,                                   
        Generator:InternalCombustionEngine,                     
        #{gen_nom_pow},                          
        GEN_SCH,                                           
        ;
        "
      idfObject = OpenStudio::IdfObject.load(new_generator_list_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_generator_list = wsObject.get

    elsif pv_power > 0 and gen_nom_pow == 0

      new_generator_list_string = "
      ElectricLoadCenter:Generators,
        gen-list,                                           
        PV-array,
        Generator:Photovoltaic,
        #{pv_power},
        ALWAYS_ON,
        ;
        "
      idfObject = OpenStudio::IdfObject.load(new_generator_list_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_generator_list = wsObject.get
    
    elsif pv_power == 0 and gen_nom_pow > 0

      # add a new generator list object
      # Only contains the Diesel gen. I'm unsure why we need to specify the generator rated power again.
      new_generator_list_string = "
      ElectricLoadCenter:Generators,
        gen-list,                                !- Name
        Diesel,                                   !- Generator 1 Name
        Generator:InternalCombustionEngine,                     !- Generator 1 Object Type
        #{gen_nom_pow},                          !- Generator 1 Rated Electric Power Output
        GEN_SCH,                                           !- Generator 1 Availability Schedule Name
        ;                                           !- Generator 1 Rated Thermal to Electrical Power Ratio
        "
      idfObject = OpenStudio::IdfObject.load(new_generator_list_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_generator_list = wsObject.get

    end

    if gen_nom_pow > 0




      fuelfactor_string = "
      FuelFactors,          !  USA national average based on eGRID, EIA 1605
        Diesel,        !- Existing Fuel Resource Name
        kg,                 !- Units of Measure (kg or m3)
        45600,                   !- Energy per Unit Factor
        1,              !- Source Energy Factor {J/J}
        ,                   !- Source Energy Schedule Name
        70.50731,          !- CO2 Emission Factor {g/MJ}
        ,                   !- CO2 Emission Factor Schedule Name
        4.08E-02,        !- CO Emission Factor {g/MJ}
        ,                   !- CO Emission Factor Schedule Name
        0.0,        !- CH4 Emission Factor {g/MJ}
        ,                   !- CH4 Emission Factor Schedule Name
        1.9,        !- NOx Emission Factor {g/MJ}
        ,                   !- NOx Emission Factor Schedule Name
        0,        !- N2O Emission Factor {g/MJ}
        ,                   !- N2O Emission Factor Schedule Name
        1.25E-01,        !- SO2 Emission Factor {g/MJ}
        ,                   !- SO2 Emission Factor Schedule Name
        0,        !- PM Emission Factor {g/MJ}
        ,                   !- PM Emission Factor Schedule Name
        1.33E-01,        !- PM10 Emission Factor {g/MJ}
        ,                   !- PM10 Emission Factor Schedule Name
        0.0,        !- PM2.5 Emission Factor {g/MJ}
        ,                   !- PM2.5 Emission Factor Schedule Name
        0.0,        !- NH3 Emission Factor {g/MJ}
        ,                   !- NH3 Emission Factor Schedule Name
        1.50E-01,        !- NMVOC Emission Factor {g/MJ}
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

    end

    # add a new inverter object
    # Let's assume it isn't great and has 95% efficiency
    if batt_storage_capacity > 0
      new_inverter_string = "
      ElectricLoadCenter:Inverter:Simple,
        Simple Ideal Inverter,                  !- Name
        Always On,                              !- Availability Schedule Name
        ,                                       !- Zone Name
        0.0,                                    !- Radiative Fraction
        0.95;                                    !- Inverter Efficiency
        "
      idfObject = OpenStudio::IdfObject.load(new_inverter_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_inverter = wsObject.get

      # add a new inverter object
      # Let's assume it isn't great and has 90% efficiency
      new_converter_string = "
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
      idfObject = OpenStudio::IdfObject.load(new_converter_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_converter = wsObject.get

      # add a new electric load center distributor
      # we need one distributor per generator if we mix AC and DC.
      new_electric_distributor_string = "
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
      idfObject = OpenStudio::IdfObject.load(new_electric_distributor_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_electric_distributor = wsObject.get

      if gen_nom_pow > 0
        # add a new EMS Sensor object
        new_EMS_sensor_string = "
        EnergyManagementSystem:Sensor,
          BattCharge, !- Name
          Battery , !- Output:Variable or Output:Meter Index Key Name
          Electric Storage Simple Charge State ; !- Output:Variable or Output:Meter Name
          "
        idfObject = OpenStudio::IdfObject.load(new_EMS_sensor_string)
        object = idfObject.get
        wsObject = workspace.addObject(object)
        new_EMS_sensor = wsObject.get

        # add a new EMS Actuator object
        new_EMS_actuator_string = "
        EnergyManagementSystem:Actuator,
          gen_SCH_override,               !- Name
          GEN_SCH,                          !- Actuated Component Unique Name
          Schedule:Constant,                    !- Actuated Component Type
          Schedule Value;                       !- Actuated Component Control Type
          "
        idfObject = OpenStudio::IdfObject.load(new_EMS_actuator_string)
        object = idfObject.get
        wsObject = workspace.addObject(object)
        new_EMS_actuator = wsObject.get

        # add a new EMS Actuator object for setting generator output
        new_EMS_actuator_string = "
        EnergyManagementSystem:Actuator,
          gen_out,               !- Name
          Diesel,                          !- Actuated Component Unique Name
          On-Site Generator Control,                    !- Actuated Component Type
          Requested Power;                       !- Actuated Component Control Type
          "
        idfObject = OpenStudio::IdfObject.load(new_EMS_actuator_string)
        object = idfObject.get
        wsObject = workspace.addObject(object)
        new_EMS_actuator = wsObject.get


        # add a new EMS Actuator object
        new_EMS_program_string = "
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
        idfObject = OpenStudio::IdfObject.load(new_EMS_program_string)
        object = idfObject.get
        wsObject = workspace.addObject(object)
        new_EMS_program = wsObject.get

        # add a new EMS program calling manager object
        new_EMS_program_calling_string = "
        EnergyManagementSystem:ProgramCallingManager,
          Battery Charging Control , !- Name
          EndOfZoneTimestepAfterZoneReporting ,    !- EnergyPlus Model Calling Point
          CheckBatteryStateOfCharge;         !- Program Name 1
          "
        idfObject = OpenStudio::IdfObject.load(new_EMS_program_calling_string)
        object = idfObject.get
        wsObject = workspace.addObject(object)
        new_EMS_program_calling = wsObject.get
      end

    else
      new_electric_distributor_string = "
      ElectricLoadCenter:Distribution,
        On-site diesel generation,      !- Name
        gen-list,                            !- Generator List Name
        TrackElectrical,                        !- Generator Operation Scheme Type
        0.0,                                    !- Demand Limit Scheme Purchased Electric Demand Limit {W}
        GEN_SCH,                                       !- Track Schedule Name Scheme Schedule Name
        ,                                       !- Track Meter Scheme Meter Name
        AlternatingCurrent;
        "
      idfObject = OpenStudio::IdfObject.load(new_electric_distributor_string)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      new_electric_distributor = wsObject.get

    # # echo the new zone's name back to the user, using the index based getString method
    # runner.registerInfo("A zone named '#{new_zone.getString(0)}' was added.")

    # # report final condition of model
    # finishing_zones = workspace.getObjectsByType('Zone'.to_IddObjectType)
    # runner.registerFinalCondition("The building finished with #{finishing_zones.size} zones.")
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
