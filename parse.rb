# encoding: UTF-8
# Extract vaccination data from official PDF reports, already converted to txt

require 'csv'

# Get the text lines containing the data in the given file
def get_data_table(filename)
  lines = []
  in_data_table = false
  File.readlines(filename).each do |line|
    # Check for table start, do nothing until then
    if line.strip =~ /^Andalucía/
      in_data_table = true
    end
    next unless in_data_table

    # Stop when the data table ends
    return lines if line=~/Fuente\: AEMPS\. El reparto de dosis/

    # Keep the data tables lines
    lines.push(line)
  end
  lines
end

# Get the data points from a bunch of text lines.
def extract_data(lines, report_date)
  # Extract four data points per line
  lines.each do |line|
    line.strip!
    next if line==''

    # The PDF to text conversion is good enough with the -table option,
    # so we just look for multiple spaces to split.
    columns = line.strip.split(/  +/)

    # Remove some footnotes for consistency across days
    columns[0].gsub!(' (**)', '')

    puts CSV::generate_line([report_date, columns].flatten)
  end

end


# Go through all the available reports and print data as CSV
puts CSV::generate_line([
  'informe',
  'comunidad autónoma',
  'dosis entregadas',
  'dosis administradas',
  '% sobre entregadas',
  'fecha actualización',
  'última vacuna registrada'
])
Dir['reports/*txt'].each do |filename|
  filename =~ /(\d{4})(\d{2})(\d{2})\.txt/
  report_date = "#{$3}/#{$2}/#{$1}"
  extract_data(get_data_table(filename), report_date)
end

