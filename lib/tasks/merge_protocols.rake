desc "Task for merging two protocols"
task :protocol_merge => :environment do

  def prompt(*args)
    print(*args)
    STDIN.gets.strip
  end

  def get_protocol(error=false, protocol_place)
    puts "It appears that was not a valid protocol id" if error
    if protocol_place == 'first'
      puts '#' * 20
      puts '#' * 20
      puts 'Enter the id of the first protocol.'
      puts 'Please note that this is the protocol that will be set as the master protocol.'
      puts 'Any attributes chosen when there are differences between the two protocols'
      puts 'will be set to this protocol.'
      id = prompt '=> '
    else
      puts 'Enter the id of the second protocol: '
      id = prompt '=> '
    end

    protocol = Protocol.where(id: id.to_i).first

    while !protocol
      protocol = get_protocol(true, protocol_place)
    end

    protocol
  end

  def get_value(error, first_value, second_value)
    puts "It appears that was not a valid number. Please enter 1 or 2" if error
    number = prompt "Enter the number of the value you would like to keep: "

    while (number != '1') && (number != '2')
      number = get_value(true, first_value, second_value)
    end

    if number == '1'
      return first_value
    else
      return second_value
    end
  end

  def resolve_conflict(attribute, first_value, second_value)
    puts "There is a conflict between the two values of this attribute: #{attribute}"
    puts "1) = #{first_value}"
    puts "2) = #{second_value}"

    get_value(false, first_value, second_value)
  end

  first_protocol = get_protocol(false, 'first')
  second_protocol = get_protocol(false, 'second')

  continue = prompt('Preparing to merge these two protocols. Are you sure you want to continue? (y/n): ')

  if (continue == 'y') || (continue == 'Y')

    first_protocol.attributes.each do |attribute, value|
      if (attribute != 'id') && (attribute != 'type') && (attribute != 'created_at') && (attribute != 'updated_at') && (attribute != 'deleted_at')
        second_protocol_attributes = second_protocol.attributes
        if value != second_protocol_attributes[attribute]
          resolved_value = resolve_conflict(attribute, value, second_protocol_attributes[attribute])
          first_protocol.assign_attributes(attribute.to_sym => resolved_value)
        end
      end
    end

    if first_protocol.valid?
    first_protocol.save
    else
      puts "#" *20
      raise first_protocol.errors.inspect
    end

    puts "The protocol attributes have been succesfully merged. Assigning project roles to master protocol..."

    second_protocol.project_roles.each do |role|
      if role.role != 'primary-pi'
        role.update_attributes(protocol_id: first_protocol.id)
      end
    end

    puts "Project roles have been transferred. Assigning service requests..."

    second_protocol.service_requests.each do |request|
      request.update_attributes(protocol_id: first_protocol.id)
    end

    puts "Service requests have been transferred. Assigning arms..."

    second_protocol.arms.each do |arm|
      arm.update_attributes(protocol_id: first_protocol.id)
    end

    puts "Arms have been transferred. Assigning documents..."

    second_protocol.documents.each do |document|
      document.update_attributes(protocol_id: first_protocol.id)
    end

    puts 'Documents have been transferred. Assigning notes...'

    second_protocol.notes.each do |note|
      note.update_attributes(notable_id: first_protocol.id)
    end
    
    puts "Updating of child objects complete"
  else
    puts 'Exiting the task...'
  end
end