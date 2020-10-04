# frozen_string_literal: true

def filename_to_i(filename)
  filename.scan(/\d+/).first.to_i
end

def messages_per_file
  50
end

def filename_to_page(filename)
  filename_to_i(filename) / messages_per_file + 1
end

def filename_to_message_numbers(filename)
  start_number = filename_to_i(filename)
  "#{start_number}-#{start_number + messages_per_file}"
end
