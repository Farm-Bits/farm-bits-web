class DataMailbox < ApplicationMailbox
  def process
    #logic_controller = LogicController.find_by_email(mail.from.first)
    mail.body.decoded.split("\n").each do |line|
      sample_time, register_name, value = line.split(',')
      if sample_time.nil? || register_name.nil? || value.nil?
        puts "Invalid line: #{line}"
        next
      end

      register = Register.where(name: register_name).first
      if register.nil?
        puts "No register found for name: #{register_name}"
        next
      end

      measurement_point = MeasurementPoint.where(register_id: register.id).first
      if measurement_point.nil?
        puts "No measurement point found for register: #{register_name}"
        next
      end

      RawValue.create(
        measurement_point_id: measurement_point.id,
        ts_from: sample_time,
        value: value
      )
    end
  end
end
