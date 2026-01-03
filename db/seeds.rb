# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
require 'csv'

ActiveRecord::Base.transaction do
  AdminUser.create!(
    name: 'Jeremy Khalfa',
    email: 'jeremy@farm-bits.com',
    password: 'Jeremy123',
    password_confirmation: 'Jeremy123'
  )

  MeasurementType.create!([
    {
      name: 'Weather',
      category: 'sensor',
      position: 1,
      measurement_subtypes_attributes: [
        { name: 'Temperature',  value_type: 'instantaneous', default_unit: '°C',   default_chart_type: 'spline', default_color: '', position: 1 },
        { name: 'Humidity',     value_type: 'instantaneous', default_unit: '%',    default_chart_type: 'spline', default_color: '', position: 2 },
        { name: 'Wind Speed',   value_type: 'instantaneous', default_unit: 'm/s',  default_chart_type: 'spline', default_color: '', position: 3 },
        { name: 'Rain',         value_type: 'accumulative',  default_unit: 'mm',   default_chart_type: 'bar',    default_color: '', position: 4 },
        { name: 'Radiation',    value_type: 'instantaneous', default_unit: 'w/m2', default_chart_type: 'spline', default_color: '', position: 5 }
      ]
    },
    {
      name: 'Ambient',
      category: 'sensor',
      position: 2,
      measurement_subtypes_attributes: [
        { name: 'Temperature',  value_type: 'instantaneous', default_unit: '°C',  default_chart_type: 'spline', default_color: '', position: 1 },
        { name: 'Humidity',     value_type: 'instantaneous', default_unit: '%',   default_chart_type: 'spline', default_color: '', position: 2 },
        { name: 'CO2',          value_type: 'instantaneous', default_unit: 'ppm', default_chart_type: 'spline', default_color: '', position: 3 }
      ]
    },
    {
      name: 'Soil',
      category: 'sensor',
      position: 3,
      measurement_subtypes_attributes: [
        { name: 'Temperature',  value_type: 'instantaneous', default_unit: '°C', default_chart_type: 'spline', default_color: '', position: 1 },
        { name: 'Humidity',     value_type: 'instantaneous', default_unit: '%',  default_chart_type: 'spline', default_color: '', position: 2 }
      ]
    },
    {
      name: 'Electricity',
      category: 'sensor',
      position: 4,
      measurement_subtypes_attributes: [
        { name: 'Power',        value_type: 'instantaneous', default_unit: 'W',  default_chart_type: 'spline', default_color: '', position: 1 },
        { name: 'Energy',       value_type: 'accumulative',  default_unit: 'Wh', default_chart_type: 'bar',    default_color: '', position: 2 },
        { name: 'Voltage',      value_type: 'instantaneous', default_unit: 'V',  default_chart_type: 'spline', default_color: '', position: 3 },
        { name: 'Current',      value_type: 'instantaneous', default_unit: 'A',  default_chart_type: 'spline', default_color: '', position: 4 }
      ]
    },
    {
      name: 'Fluid',
      category: 'sensor',
      position: 5,
      measurement_subtypes_attributes: [
        { name: 'Pressure',     value_type: 'instantaneous', default_unit: 'Bar',  default_chart_type: 'spline', default_color: '', position: 1 },
        { name: 'Flow Rate',    value_type: 'instantaneous', default_unit: 'm3/s', default_chart_type: 'spline', default_color: '', position: 2 },
        { name: 'Amount',       value_type: 'accumulative',  default_unit: 'L',    default_chart_type: 'bar',    default_color: '', position: 3 }
      ]
    },
    {
      name: 'Control',
      category: 'control',
      position: 6,
      measurement_subtypes_attributes: [
        { name: 'Irrigation',  value_type: 'status', default_unit: 'Closed/Open', default_chart_type: 'spline', default_color: '', position: 1 },
        { name: 'Fertigation', value_type: 'status', default_unit: 'Closed/Open', default_chart_type: 'spline', default_color: '', position: 2 },
        { name: 'Curtain',     value_type: 'status', default_unit: 'Closed/Open', default_chart_type: 'spline', default_color: '', position: 3 },
        { name: 'Fan',         value_type: 'status', default_unit: 'Off/On',      default_chart_type: 'spline', default_color: '#5C6267', position: 4 },
        { name: 'Heater',      value_type: 'status', default_unit: 'Off/On',      default_chart_type: 'spline', default_color: '#FF8C00', position: 5 },
        { name: 'Window',      value_type: 'status', default_unit: 'Closed/Open', default_chart_type: 'spline', default_color: '#39A0CA', position: 6 },
        { name: 'Light',       value_type: 'status', default_unit: 'Off/On',      default_chart_type: 'spline', default_color: '', position: 7 },
        { name: 'Humidifier',  value_type: 'status', default_unit: 'Off/On',      default_chart_type: 'spline', default_color: '', position: 8 },
        { name: 'Pump',        value_type: 'status', default_unit: 'Off/On',      default_chart_type: 'spline', default_color: '', position: 9 },
        { name: 'Valve',       value_type: 'status', default_unit: 'Closed',      default_chart_type: 'spline', default_color: '#398439', position: 10 }
      ]
    }
  ])

  eliwell_manufacturer = Manufacturer.create!(name: 'Eliwell')

  free_advance_model = Model.create!(
    name: 'FreeAdvance AVC12600/C/L/U/I (AVC126006I500)',
    device_type: 'plc',
    manufacturer: eliwell_manufacturer
  )

  free_advance_first_version = PlcVersion.create!(
    name: 'V0',
    version_code: '0.1',
    handler_class: 'Plc::Handlers::FreeAdvanceV0',
    is_latest: true,
    is_supported: true,
    model: free_advance_model
  )

  interfaces_data = [
    { name: 'DIL1',  communication_type: 'digital_input',  description: 'Digital Input 1',   position: 1,  plc_version: free_advance_first_version },
    { name: 'DIL2',  communication_type: 'digital_input',  description: 'Digital Input 2',   position: 2,  plc_version: free_advance_first_version },
    { name: 'DIL3',  communication_type: 'digital_input',  description: 'Digital Input 3',   position: 3,  plc_version: free_advance_first_version },
    { name: 'DIL4',  communication_type: 'digital_input',  description: 'Digital Input 4',   position: 4,  plc_version: free_advance_first_version },
    { name: 'DIL5',  communication_type: 'digital_input',  description: 'Digital Input 5',   position: 5,  plc_version: free_advance_first_version },
    { name: 'DIL6',  communication_type: 'digital_input',  description: 'Digital Input 6',   position: 6,  plc_version: free_advance_first_version },
    { name: 'DIL7',  communication_type: 'digital_input',  description: 'Digital Input 7',   position: 7,  plc_version: free_advance_first_version },
    { name: 'DIL8',  communication_type: 'digital_input',  description: 'Digital Input 8',   position: 8,  plc_version: free_advance_first_version },
    { name: 'DIL9',  communication_type: 'digital_input',  description: 'Digital Input 9',   position: 9,  plc_version: free_advance_first_version },
    { name: 'DIL10', communication_type: 'digital_input',  description: 'Digital Input 10',  position: 10, plc_version: free_advance_first_version },
    { name: 'DIL11', communication_type: 'digital_input',  description: 'Digital Input 11',  position: 11, plc_version: free_advance_first_version },
    { name: 'DIL12', communication_type: 'digital_input',  description: 'Digital Input 12',  position: 12, plc_version: free_advance_first_version },
    { name: 'DOL1',  communication_type: 'digital_output', description: 'Digital Output 1',  position: 13, plc_version: free_advance_first_version },
    { name: 'DOL2',  communication_type: 'digital_output', description: 'Digital Output 2',  position: 14, plc_version: free_advance_first_version },
    { name: 'DOL3',  communication_type: 'digital_output', description: 'Digital Output 3',  position: 15, plc_version: free_advance_first_version },
    { name: 'DOL4',  communication_type: 'digital_output', description: 'Digital Output 4',  position: 16, plc_version: free_advance_first_version },
    { name: 'DOL5',  communication_type: 'digital_output', description: 'Digital Output 5',  position: 17, plc_version: free_advance_first_version },
    { name: 'DOL6',  communication_type: 'digital_output', description: 'Digital Output 6',  position: 18, plc_version: free_advance_first_version },
    { name: 'DOL7',  communication_type: 'digital_output', description: 'Digital Output 7',  position: 19, plc_version: free_advance_first_version },
    { name: 'DOL8',  communication_type: 'digital_output', description: 'Digital Output 8',  position: 20, plc_version: free_advance_first_version },
    { name: 'DOL9',  communication_type: 'digital_output', description: 'Digital Output 9',  position: 21, plc_version: free_advance_first_version },
    { name: 'DOL10', communication_type: 'digital_output', description: 'Digital Output 10', position: 22, plc_version: free_advance_first_version },
    { name: 'DOL11', communication_type: 'digital_output', description: 'Digital Output 11', position: 23, plc_version: free_advance_first_version },
    { name: 'DOL12', communication_type: 'digital_output', description: 'Digital Output 12', position: 24, plc_version: free_advance_first_version },
    { name: 'AIL1',  communication_type: 'analog_input',   description: 'Analog Input 1',    position: 25, plc_version: free_advance_first_version },
    { name: 'AIL2',  communication_type: 'analog_input',   description: 'Analog Input 2',    position: 26, plc_version: free_advance_first_version },
    { name: 'AIL3',  communication_type: 'analog_input',   description: 'Analog Input 3',    position: 27, plc_version: free_advance_first_version },
    { name: 'AIL4',  communication_type: 'analog_input',   description: 'Analog Input 4',    position: 28, plc_version: free_advance_first_version },
    { name: 'AIL5',  communication_type: 'analog_input',   description: 'Analog Input 5',    position: 29, plc_version: free_advance_first_version },
    { name: 'AIL6',  communication_type: 'analog_input',   description: 'Analog Input 6',    position: 30, plc_version: free_advance_first_version },
    { name: 'AIL7',  communication_type: 'analog_input',   description: 'Analog Input 7',    position: 31, plc_version: free_advance_first_version },
    { name: 'AIL8',  communication_type: 'analog_input',   description: 'Analog Input 8',    position: 32, plc_version: free_advance_first_version },
    { name: 'AIL9',  communication_type: 'analog_input',   description: 'Analog Input 9',    position: 33, plc_version: free_advance_first_version },
    { name: 'AIL10', communication_type: 'analog_input',   description: 'Analog Input 10',   position: 34, plc_version: free_advance_first_version },
    { name: 'AIL11', communication_type: 'analog_input',   description: 'Analog Input 11',   position: 35, plc_version: free_advance_first_version },
    { name: 'AIL12', communication_type: 'analog_input',   description: 'Analog Input 12',   position: 36, plc_version: free_advance_first_version },
    { name: 'AOL1',  communication_type: 'analog_output',  description: 'Analog Output 1',   position: 37, plc_version: free_advance_first_version },
    { name: 'AOL2',  communication_type: 'analog_output',  description: 'Analog Output 2',   position: 38, plc_version: free_advance_first_version },
    { name: 'AOL3',  communication_type: 'analog_output',  description: 'Analog Output 3',   position: 39, plc_version: free_advance_first_version },
    { name: 'AOL4',  communication_type: 'analog_output',  description: 'Analog Output 4',   position: 40, plc_version: free_advance_first_version },
    { name: 'AOL5',  communication_type: 'analog_output',  description: 'Analog Output 5',   position: 41, plc_version: free_advance_first_version },
    { name: 'AOL6',  communication_type: 'analog_output',  description: 'Analog Output 6',   position: 42, plc_version: free_advance_first_version }
  ]
  interfaces = Interface.create!(interfaces_data)

  interfaces = {}
  interfaces_data.each do |iface|
    interfaces[iface[:name]] = Interface.find_by(name: iface[:name], plc_version: free_advance_first_version)
  end

  type_mapping = {
    'BOOL' => 'boolean',
    'SINT' => 'int8',
    'USINT' => 'uint8',
    'INT' => 'int16',
    'UINT' => 'uint16',
    'DINT' => 'int32',
    'UDINT' => 'uint32',
    'BYTE' => 'uint8',
    'WORD' => 'uint16',
    'DWORD' => 'uint32',
    'REAL' => 'float32',
    'LREAL' => 'float64',
    'STRING' => 'string',
    'WSTRING' => 'utf16_string',
    'DATE' => 'date_seconds',
    'LDATE' => 'date_nanoseconds',
    'TIME' => 'time_milliseconds',
    'LTIME' => 'time_nanoseconds',
    'DATE_AND_TIME' => 'datetime_seconds',
    'LDATE_AND_TIME' => 'datetime_nanoseconds',
    'TIME_OF_DAY' => 'timeofday_milliseconds',
    'lTIME_OF_DAY' => 'timeofday_nanoseconds'
  }

  registers = []
  rows = CSV.read('lib/assets/eliwell_register_templates.csv', headers: true)
  rows.each_with_index do |row, index|
    data = row

    # Address,Name,Type,Value,Um,Default,Min,Max,Description,Count
    address = data[0].to_i
    name = data[1]
    type = data[2]
    um = data[4]
    default_value = data[5]
    min_value = data[6]
    max_value = data[7]
    description = data[8]
    address_count = data[9].to_i

    register_type = 'holding'
    read_only = false
    if address > 0 && address <= 9999
      register_type = 'coil'
      read_only = false
    elsif address > 10000 && address <= 19999
      register_type = 'discrete'
      read_only = true
    elsif address > 30000 && address <= 39999
      register_type = 'input'
      read_only = true
    elsif address > 40000 && address <= 49999
      register_type = 'holding'
      read_only = false
    else
      register_type = 'holding'
      read_only = false
    end

    value_format = 'numeric'
    if um == 'flag' || type == 'BOOL'
      value_format = 'boolean'
    elsif ['BYTE', 'WORD', 'DWORD', 'STRING', 'WSTRING'].include?(type)
      value_format = 'ascii_string'
    end

    enum_values = nil
    data_type = type_mapping[type]
    if type == 'enum'
      value_format = 'enum'
      data_type = 'uint8'
      if name.start_with?('Cfg_AI')
        enum_values = {
          '0': 'NTC(NK103)',
          '1': 'DI',
          '2': 'NTC(103AT)',
          '3': '4/20mA',
          '4': '0/10V',
          '5': '0/5V(Ratiometric)',
          '6': 'PT1000',
          '7': 'hO(NTC)',
          '8': 'daO(PT1000)',
          '9': 'PTC',
          '10': '0/5V',
          '11': '0/20mA'
        }
      elsif name.start_with?('Cfg_AO')
        enum_values = {
          '0': 'Current modulation',
          '1': 'Current ON/OFF',
          '2': 'Voltage modulation',
          '3': 'PWM mode'
        }
      elsif name == 'Temp_UM'
        enum_values = {
          '0': '°C',
          '1': '°F'
        }
      elsif name.start_with?('Proto_RS485_OB') || name == 'Proto_RS485_PI'
        enum_values = {
          '2': 'uNET',
          '3': 'Modbus/RTU',
          '4': 'BACnet MS/TP'
        }
      elsif name.start_with?('Parity_RS485_OB') || name == 'Parity_RS485_PI' || name == 'Parity_RS232_PI'
        enum_values = {
          '0': 'Null',
          '1': 'Odd',
          '2': 'Even'
        }
      elsif name.start_with?('Baud_RS485_OB') || name == 'Baud_RS485_PI' || name == 'Baud_RS232_PI'
        enum_values = {
          '0': '9600',
          '1': '19200',
          '2': '38400',
          '3': '57600',
          '4': '76800',
          '5': '115200'
        }
      elsif name == 'Baud_CAN_OB' || name == 'Baud_CAN_PI'
        enum_values = {
          '2': '500 Kb/s',
          '3': '250 Kb/s',
          '4': '125 Kb/s',
          '5': '100 Kb/s',
          '6': '50 Kb/s'
        }
      elsif name == 'Proto_RS232_PI'
        enum_values = {
          '2': 'uNET',
          '3': 'Modbus/RTU'
        }
      elsif name == 'MbMRtu_DisByPar'
        enum_values = {
          '0': 'Enabled',
          '1': 'Disabled'
        }
      elsif name.start_with?('LED')
        enum_values = {
          '0': 'Off',
          '1': 'On',
          '2': 'Blink'
        }
      elsif name == 'BACKLIGHT'
        enum_values = {
          '0': 'Off',
          '1': 'On',
          '2': 'Blink',
          '3': 'Timed',
          '4': 'Timed running'
        }
      elsif name.end_with?('_volume')
        enum_values = {
          '0': 'NOR Flash',
          '1': 'microSD card'
        }
      elsif name == 'microSD_command'
        enum_values = {
          '0': 'No command',
          '1': 'Mount microSD, after plugged the microSD',
          '2': 'Unmount microSD, before unplug the microSD'
        }
      elsif name == 'microSD_status'
        enum_values = {
          '0': 'command completed',
          '1': 'command processing',
          '255': 'command failed',
          '254': 'microSD yet mounted',
          '252': 'microSD not present'
        }
      elsif name == 'USB_Host_command'
        enum_values = {
          '0': 'No command',
          '7': 'load PARAM.BIN from USBH',
          '8': 'load PLCIEC.COD from USBH to PLC_volume',
          '9': 'load HMIIEC.COD from USBH to HMI_volume',
          '10': 'load PARAM.DAT or PARAM.RAW from USBH',
          '11': 'save PARAM.DAT to USBH',
          '12': 'load CONNEC.PAR from USBH to PAR_volume',
          '13': 'load HMIREM.KBD from USBH to REM_volume',
          '14': 'save sysUsbFileName file from microSD to USBH, file name can be name.ext or *.ext',
          '15': 'load sysUsbFileName file from USBH to DAT_volume (ext=DAT) otherwise to microSD, file name can be name.ext or *.ext',
          '16': 'load file sysUsbFileName from DAT_volume, file must have PARAM.DAT format and filename name.DAT or name .RAW',
          '18': 'load BACNET.DAT from USBH to DAT_volume',
          '19': 'save PARAM.BIN to USBH',
          '20': 'save LON.XIF to NOR flash',
          '21': 'save LON.XIF to USBH',
          '24': 'load BINDIN.PAR from USBH to PAR_volume',
          '108': 'load PLCIEC.COD from USBH to NOR flash',
          '109': 'load HMIIEC.COD from USBH to NOR flash',
          '112': 'load CONNEC.PAR from USBH to NOR flash',
          '113': 'load HMIREM.KBD from USBH to NOR flash',
          '114': 'save sysUsbFileName file from NOR flash to USBH, file name can be name.ext or *.ext',
          '115': 'load sysUsbFileName file from USBH, file name can be name.ext or *.ext, to NOR flash',
          '116': 'load file sysUsbFileName from NOR flash, file must have PARAM.DAT format and filename name.DAT or name .RAW',
          '118': 'load BACNET.DAT from USBH to NOR flash',
          '208': 'load PLCIEC.COD from USBH to microSD',
          '209': 'load HMIIEC.COD from USBH to microSD',
          '212': 'load CONNEC.PAR from USBH to microSD',
          '213': 'load HMIREM.KBD from USBH to microSD',
          '214': 'save sysUsbFileName file from microSD to USBH, file name can be name.ext or *.ext',
          '215': 'load sysUsbFileName file from USBH, file name can be name.ext or *.ext, to microSD',
          '216': 'load file sysUsbFileName from microSD, file must have PARAM.DAT format and filename name.DAT or name .RAW',
          '218': 'load BACNET.DAT from USBH to microSD'
        }
      elsif name == 'USB_Host_status'
        enum_values = {
          '0': 'command completed',
          '1': 'command processing',
          '255': 'command failed',
          '254': 'file not present',
          '253': 'file too long',
          '252': 'USBH not connected',
          '251': 'file not compatible',
          '250': 'some parameters fails',
          '249': 'write file failed',
          '248': 'open file in write failed'
        }
      elsif name == 'HTTP_AdminPswConfirmStatus'
        enum_values = {
          '0': 'no operation or operation done correctly',
          '1': 'request on going',
          '2': 'request to confirm new password failed	(to save in EEPROM)',
          '3': 'request to confirm new password failed (old password is not the previous one)',
          '4': 'password at first access has to be changed',
          '5': 'password changed correctly',
          '6': 'password changed correctly and wait Modbus TCP slave socket opening',
          '7': 'password changed correctly and Modbus TCP slave socket opened',
          '8': 'password at first access has to be changed but not now, wait a moment',
          '9': 'first password change was done with default factory password'
        }
      end
    end

    category = 'configuration'
    default_data_collection_enabled = false
    default_polling_interval_seconds = nil
    if address >= 8960 && address <= 9001
      if address <= 8983
        category = 'sensor'
      else
        category = 'control'
      end

      default_data_collection_enabled = true
      default_polling_interval_seconds = 300
    else
      if name.end_with?('status') || name.end_with?('Status')
        category = 'diagnostic'
      elsif name.start_with?('AIL') || name.start_with?('DIL')
        category = 'sensor'
      elsif name.start_with?('AOL') || name.start_with?('DOL')
        category = 'control'
        if name.start_with?('AOL')
          data_type = 'int16'
        end
      end
    end

    registers.push(
      name: name,
      label: name,
      description: description,
      address: address,
      address_count: address_count,
      register_type: register_type,
      data_type: data_type,
      byte_order: 'big_endian',
      value_format: value_format,
      factor: 1,
      offset: 0,
      category: category,
      read_only: read_only,
      min_value: min_value,
      max_value: max_value,
      default_value: default_value,
      enum_values: enum_values,
      default_data_collection_enabled: default_data_collection_enabled,
      default_polling_interval_seconds: default_polling_interval_seconds,
      position: index + 1,
      plc_version: free_advance_first_version
    )
  end
  register_templates = RegisterTemplate.create!(registers)

  semtech_manufacturer = Manufacturer.create!(
    name: 'Semtech',
    models_attributes: [{ name: 'LX40 EMEA', device_type: 'terminal' }]
  )
end
