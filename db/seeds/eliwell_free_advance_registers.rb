# Usage:
#   rails runner db/seeds/eliwell_free_advance_registers.rb

require 'csv'

ActiveRecord::Base.transaction do
  eliwell_manufacturer = Manufacturer.create!(name: 'Eliwell')

  free_advance_model = Model.create!(
    name: 'FreeAdvance AVC12600/C/L/U/I (AVC126006I500)',
    device_type: 'plc',
    manufacturer: eliwell_manufacturer
  )

  free_advance_first_version = PlcVersion.create!(
    name: 'V1',
    version_code: '1.0',
    is_latest: true,
    is_supported: true,
    model: free_advance_model
  )

  interfaces_data = [
    { name: 'DIL1',  communication_type: 'digital_input',  description: 'Digital Input 1',   io_number: 1,  plc_version: free_advance_first_version },
    { name: 'DIL2',  communication_type: 'digital_input',  description: 'Digital Input 2',   io_number: 2,  plc_version: free_advance_first_version },
    { name: 'DIL3',  communication_type: 'digital_input',  description: 'Digital Input 3',   io_number: 3,  plc_version: free_advance_first_version },
    { name: 'DIL4',  communication_type: 'digital_input',  description: 'Digital Input 4',   io_number: 4,  plc_version: free_advance_first_version },
    { name: 'DIL5',  communication_type: 'digital_input',  description: 'Digital Input 5',   io_number: 5,  plc_version: free_advance_first_version },
    { name: 'DIL6',  communication_type: 'digital_input',  description: 'Digital Input 6',   io_number: 6,  plc_version: free_advance_first_version },
    { name: 'DIL7',  communication_type: 'digital_input',  description: 'Digital Input 7',   io_number: 7,  plc_version: free_advance_first_version },
    { name: 'DIL8',  communication_type: 'digital_input',  description: 'Digital Input 8',   io_number: 8,  plc_version: free_advance_first_version },
    { name: 'DIL9',  communication_type: 'digital_input',  description: 'Digital Input 9',   io_number: 9,  plc_version: free_advance_first_version },
    { name: 'DIL10', communication_type: 'digital_input',  description: 'Digital Input 10',  io_number: 10, plc_version: free_advance_first_version },
    { name: 'DIL11', communication_type: 'digital_input',  description: 'Digital Input 11',  io_number: 11, plc_version: free_advance_first_version },
    { name: 'DIL12', communication_type: 'digital_input',  description: 'Digital Input 12',  io_number: 12, plc_version: free_advance_first_version },
    { name: 'AIL1',  communication_type: 'analog_input',   description: 'Analog Input 1',    io_number: 1,  plc_version: free_advance_first_version },
    { name: 'AIL2',  communication_type: 'analog_input',   description: 'Analog Input 2',    io_number: 2,  plc_version: free_advance_first_version },
    { name: 'AIL3',  communication_type: 'analog_input',   description: 'Analog Input 3',    io_number: 3,  plc_version: free_advance_first_version },
    { name: 'AIL4',  communication_type: 'analog_input',   description: 'Analog Input 4',    io_number: 4,  plc_version: free_advance_first_version },
    { name: 'AIL5',  communication_type: 'analog_input',   description: 'Analog Input 5',    io_number: 5,  plc_version: free_advance_first_version },
    { name: 'AIL6',  communication_type: 'analog_input',   description: 'Analog Input 6',    io_number: 6,  plc_version: free_advance_first_version },
    { name: 'AIL7',  communication_type: 'analog_input',   description: 'Analog Input 7',    io_number: 7,  plc_version: free_advance_first_version },
    { name: 'AIL8',  communication_type: 'analog_input',   description: 'Analog Input 8',    io_number: 8,  plc_version: free_advance_first_version },
    { name: 'AIL9',  communication_type: 'analog_input',   description: 'Analog Input 9',    io_number: 9,  plc_version: free_advance_first_version },
    { name: 'AIL10', communication_type: 'analog_input',   description: 'Analog Input 10',   io_number: 10, plc_version: free_advance_first_version },
    { name: 'AIL11', communication_type: 'analog_input',   description: 'Analog Input 11',   io_number: 11, plc_version: free_advance_first_version },
    { name: 'AIL12', communication_type: 'analog_input',   description: 'Analog Input 12',   io_number: 12, plc_version: free_advance_first_version },
    { name: 'AOL1',  communication_type: 'analog_output',  description: 'Analog Output 1',   io_number: 1,  plc_version: free_advance_first_version },
    { name: 'AOL2',  communication_type: 'analog_output',  description: 'Analog Output 2',   io_number: 2,  plc_version: free_advance_first_version },
    { name: 'AOL3',  communication_type: 'analog_output',  description: 'Analog Output 3',   io_number: 3,  plc_version: free_advance_first_version },
    { name: 'AOL4',  communication_type: 'analog_output',  description: 'Analog Output 4',   io_number: 4,  plc_version: free_advance_first_version },
    { name: 'AOL5',  communication_type: 'analog_output',  description: 'Analog Output 5',   io_number: 5,  plc_version: free_advance_first_version },
    { name: 'AOL6',  communication_type: 'analog_output',  description: 'Analog Output 6',   io_number: 6,  plc_version: free_advance_first_version },
    { name: 'DOL1',  communication_type: 'digital_output', description: 'Digital Output 1',  io_number: 1,  plc_version: free_advance_first_version },
    { name: 'DOL2',  communication_type: 'digital_output', description: 'Digital Output 2',  io_number: 2,  plc_version: free_advance_first_version },
    { name: 'DOL3',  communication_type: 'digital_output', description: 'Digital Output 3',  io_number: 3,  plc_version: free_advance_first_version },
    { name: 'DOL4',  communication_type: 'digital_output', description: 'Digital Output 4',  io_number: 4,  plc_version: free_advance_first_version },
    { name: 'DOL5',  communication_type: 'digital_output', description: 'Digital Output 5',  io_number: 5,  plc_version: free_advance_first_version },
    { name: 'DOL6',  communication_type: 'digital_output', description: 'Digital Output 6',  io_number: 6,  plc_version: free_advance_first_version },
    { name: 'DOL7',  communication_type: 'digital_output', description: 'Digital Output 7',  io_number: 7,  plc_version: free_advance_first_version },
    { name: 'DOL8',  communication_type: 'digital_output', description: 'Digital Output 8',  io_number: 8,  plc_version: free_advance_first_version },
    { name: 'DOL9',  communication_type: 'digital_output', description: 'Digital Output 9',  io_number: 9,  plc_version: free_advance_first_version },
    { name: 'DOL10', communication_type: 'digital_output', description: 'Digital Output 10', io_number: 10, plc_version: free_advance_first_version },
    { name: 'DOL11', communication_type: 'digital_output', description: 'Digital Output 11', io_number: 11, plc_version: free_advance_first_version },
    { name: 'DOL12', communication_type: 'digital_output', description: 'Digital Output 12', io_number: 12, plc_version: free_advance_first_version }
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

    # Address,Name,Type,Value,Um,Default,Min,Max,Description,Count,Register Type,Read Only,Category,Read Group,Read Address,Read Offset,Interfaces
    address = data[0].to_i
    name = data[1]
    type = data[2]
    um = data[4]
    default_value = data[5]
    min_value = data[6]
    max_value = data[7]
    description = data[8]
    address_count = data[9].to_i
    register_type = data[10]
    read_only = data[11].to_i
    category = data[12]
    bulk_read_group = data[13]
    bulk_read_address = data[14]
    bulk_read_offset = data[15]
    interface_names = data[16] ? data[16].split(',').map(&:strip) : []

    value_format = 'numeric'
    if name.include?('Time') || name.start_with?('ManualStart')
      value_format = 'time_of_day'
    elsif name.include?('Duration') || name.start_with?('ManualOn') || name.start_with?('DcOn')
      value_format = 'duration_seconds'
    elsif um == 'flag' || type == 'BOOL'
      value_format = 'boolean'
    elsif ['BYTE', 'WORD', 'DWORD', 'STRING', 'WSTRING'].include?(type)
      value_format = 'ascii_string'
    end

    enum_values = nil
    data_type = type_mapping[type]
    if name.start_with?('AOL')
      data_type = 'int16'
    end
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

    interface_register_mappings_attributes = interface_names.map.with_index do |iname, index|
      {
        description: description,
        position: index + 1,
        interface: interfaces[iname]
      }
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
      bulk_read_group: bulk_read_group,
      bulk_read_address: bulk_read_address,
      bulk_read_offset: bulk_read_offset,
      read_only: read_only,
      user_visibility: interface_register_mappings_attributes.any? ? 'visible' : 'hidden',
      min_value: min_value,
      max_value: max_value,
      default_value: default_value,
      enum_values: enum_values,
      position: index + 1,
      plc_version: free_advance_first_version,
      interface_register_mappings_attributes: interface_register_mappings_attributes
    )
  end
  register_templates = RegisterTemplate.create!(registers)

  # Example: Setting up visibility conditions for Analog Input configuration registers
  #
  # The input type selector (Cfg_AI1, Cfg_AI2, etc.) determines which calibration
  # registers are relevant. For example:
  #   - NTC sensors (values 0, 2, 7) need NTC gain/offset
  #   - PT1000 sensors (values 6, 8) need PT1000 gain/offset
  #   - 4-20mA inputs (value 3) need mA gain/offset
  #   - 0-10V inputs (value 4) need 10V gain/offset
  #   - etc.
  #
  # The Cfg_AI* register enum values:
  #   0 = NTC(NK103)
  #   1 = DI (Digital Input mode)
  #   2 = NTC(103AT)
  #   3 = 4/20mA
  #   4 = 0/10V
  #   5 = 0/5V(Ratiometric)
  #   6 = PT1000
  #   7 = hO(NTC)
  #   8 = daO(PT1000)
  #   9 = PTC
  #   10 = 0/5V
  #   11 = 0/20mA

  # This method sets up the proper group structure and visibility conditions
  def setup_analog_input_configuration(plc_version)
    # For each analog input interface (AI1-AI12), set up the group
    (1..12).each do |ai_num|
      interface_name = "AI#{ai_num}"
      group_name = "analog_input_#{ai_num}_config"

      # Find the input type selector register
      input_type_register = plc_version.register_templates.find_by(name: "Cfg_#{interface_name}")
      next unless input_type_register

      # Update the input type selector to be the controller
      input_type_register.update!(
        group_name: group_name,
        group_role: "input_type_selector",
        visibility_conditions: {} # Always visible
      )

      # NTC gain/offset - visible for NTC types (0, 2, 7)
      ntc_values = %w[0 2 7]
      update_calibration_register(
        plc_version,
        "Gain_Ntc_#{interface_name}",
        group_name,
        "ntc_gain",
        { "input_type_selector" => ntc_values }
      )
      update_calibration_register(
        plc_version,
        "Offs_Ntc_#{interface_name}",
        group_name,
        "ntc_offset",
        { "input_type_selector" => ntc_values }
      )

      # PT1000 gain/offset - visible for PT1000 types (6, 8)
      pt1000_values = %w[6 8]
      update_calibration_register(
        plc_version,
        "Gain_PT1000_#{interface_name}",
        group_name,
        "pt1000_gain",
        { "input_type_selector" => pt1000_values }
      )
      update_calibration_register(
        plc_version,
        "Offs_PT1000_#{interface_name}",
        group_name,
        "pt1000_offset",
        { "input_type_selector" => pt1000_values }
      )

      # 4-20mA gain/offset - visible for mA types (3, 11)
      ma_values = %w[3 11]
      update_calibration_register(
        plc_version,
        "Gain_mA_#{interface_name}",
        group_name,
        "ma_gain",
        { "input_type_selector" => ma_values }
      )
      update_calibration_register(
        plc_version,
        "Offs_mA_#{interface_name}",
        group_name,
        "ma_offset",
        { "input_type_selector" => ma_values }
      )

      # 0-10V gain/offset - visible for 10V type (4)
      v10_values = %w[4]
      update_calibration_register(
        plc_version,
        "Gain_10V_#{interface_name}",
        group_name,
        "v10_gain",
        { "input_type_selector" => v10_values }
      )
      update_calibration_register(
        plc_version,
        "Offs_10V_#{interface_name}",
        group_name,
        "v10_offset",
        { "input_type_selector" => v10_values }
      )

      # 0-5V gain/offset - visible for 5V type (10)
      v5_values = %w[10]
      update_calibration_register(
        plc_version,
        "Gain_5V_#{interface_name}",
        group_name,
        "v5_gain",
        { "input_type_selector" => v5_values }
      )
      update_calibration_register(
        plc_version,
        "Offs_5V_#{interface_name}",
        group_name,
        "v5_offset",
        { "input_type_selector" => v5_values }
      )

      # 0-5Vr (ratiometric) gain/offset - visible for 5Vr type (5)
      v5r_values = %w[5]
      update_calibration_register(
        plc_version,
        "Gain_5Vr_#{interface_name}",
        group_name,
        "v5r_gain",
        { "input_type_selector" => v5r_values }
      )
      update_calibration_register(
        plc_version,
        "Offs_5Vr_#{interface_name}",
        group_name,
        "v5r_offset",
        { "input_type_selector" => v5r_values }
      )

      # PTC gain/offset - visible for PTC type (9)
      ptc_values = %w[9]
      update_calibration_register(
        plc_version,
        "Gain_PTC_#{interface_name}",
        group_name,
        "ptc_gain",
        { "input_type_selector" => ptc_values }
      )
      update_calibration_register(
        plc_version,
        "Offs_PTC_#{interface_name}",
        group_name,
        "ptc_offset",
        { "input_type_selector" => ptc_values }
      )

      # Full scale min/max - visible for scalable types (3, 4, 5, 10, 11)
      scalable_values = %w[3 4 5 10 11]
      update_scale_register(
        plc_version,
        "FullScaleMin_#{interface_name}",
        group_name,
        "scale_min",
        { "input_type_selector" => scalable_values },
        { "less_than" => { "group_role" => "scale_max" } }
      )
      update_scale_register(
        plc_version,
        "FullScaleMax_#{interface_name}",
        group_name,
        "scale_max",
        { "input_type_selector" => scalable_values },
        { "greater_than" => { "group_role" => "scale_min" } }
      )

      # Calibration (differential) - always visible when not in DI mode
      non_di_values = %w[0 2 3 4 5 6 7 8 9 10 11]
      update_calibration_register(
        plc_version,
        "Calibration_#{interface_name}",
        group_name,
        "calibration_diff",
        { "input_type_selector" => non_di_values }
      )
    end
  end

  def update_calibration_register(plc_version, name, group_name, role, visibility)
    register = plc_version.register_templates.find_by(name: name)
    return unless register

    register.update!(
      group_name: group_name,
      group_role: role,
      visibility_conditions: visibility
    )
  end

  def update_scale_register(plc_version, name, group_name, role, visibility, validation)
    register = plc_version.register_templates.find_by(name: name)
    return unless register

    register.update!(
      group_name: group_name,
      group_role: role,
      visibility_conditions: visibility,
      validation_rules: validation
    )
  end

  # Example: Set up digital input configuration (FDI)
  def setup_digital_input_configuration(plc_version)
    (1..8).each do |fdi_num|
      interface_name = "FDI#{fdi_num}"
      group_name = "digital_input_#{fdi_num}_config"

      # Frequency setting - always visible for digital inputs
      freq_register = plc_version.register_templates.find_by(name: "#{interface_name}_frequency")
      freq_register&.update!(
        group_name: group_name,
        group_role: "frequency",
        visibility_conditions: {}
      )

      # Reset counter - always visible
      reset_register = plc_version.register_templates.find_by(name: "#{interface_name}_reset_counter")
      reset_register&.update!(
        group_name: group_name,
        group_role: "reset_counter",
        visibility_conditions: {}
      )
    end
  end

  CLOCK_REGISTER_ROLES = {
    'sysClockSet_seconds'  => 'seconds',
    'sysClockSet_minutes'  => 'minutes',
    'sysClockSet_hours'    => 'hours',
    'sysClockSet_dayweek'  => 'day_of_week',
    'sysClockSet_daymonth' => 'day_of_month',
    'sysClockSet_month'    => 'month',
    'sysClockSet_year'     => 'year',
    'sysClockSet_upload'   => 'upload_trigger'
  }.freeze

  def setup_system_clock_group(plc_version)
    CLOCK_REGISTER_ROLES.each do |name, role|
      clock_register = plc_version.register_templates.find_by(name: name)
      clock_register&.update!(
        group_name: 'set_system_clock',
        group_role: role
      )
    end
  end

  setup_analog_input_configuration(free_advance_first_version)
  setup_digital_input_configuration(free_advance_first_version)
  setup_system_clock_group(free_advance_first_version)
end
