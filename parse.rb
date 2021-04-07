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
def extract_data(lines, filename)
  filename =~ /(\d{4})(\d{2})(\d{2})\.txt/
  report_date = "#{$1}#{$2}#{$3}" # Date in ISO format, handy to sort and test
  formatted_date = "#{$3}/#{$2}/#{$1}"

  # Extract data points per line
  lines.each do |line|
    line.strip!
    next if line==''

    # The PDF to text conversion is good enough with the -table option,
    # so we just look for multiple spaces to split.
    columns = line.split(/  +/)

    # Remove some footnotes for consistency across days
    columns[0].gsub!(' (*)', '')
    columns[0].gsub!(' (**)', '')

    # Castilla La Mancha sometimes breaks across lines
    columns[0] = 'Castilla La Mancha' if columns[0]=='Castilla La'
    next if columns[0]=='Mancha'

    # The first three reports were inconsistent about the type and number
    # of dates provided. Things have settled now (20210114), but we need
    # to fix one particular day.
    columns.delete_at(4) if report_date=='20210105'

    # Starting 20210114, we get data for a second vaccine (Moderna), not just Pfizer
    if report_date<'20210114'
      columns.insert(2, columns[1]) # The Pfizer doses equal the total doses
      columns.insert(2, nil)        # Add a blank column for Moderna
    end

    # Starting 20210209, we get data for a third vaccine (AstraZeneca)
    if report_date<'20210209'
      columns.insert(3, nil)        # Add a blank column for AstraZeneca
    end

    # Starting 20210118, we get data for # people with completed treatment
    if report_date<'20210118'
      columns.insert(7, nil)        # Add a blank column, no one had two doses
    end

    # Starting 20210406, we get data for # people with one dose
    if report_date<'20210406'
      # Add a blank column, although this could be deduced from the other columns,
      # since all the vaccines needed two doses. I.e.
      #   Total doses - 2 * fully vaccinated = people with one dose
      columns.insert(7, nil)
    end

    # The summary line doesn't have a date at the end, which makes sense.
    # Github doesn't like that, so we just add an empty cell to make
    # Github's web preview work well.
    columns.push(nil) if columns[0]=='Totales'

    # And output the result of all this.
    puts CSV::generate_line([formatted_date, columns].flatten)
  end

end


# Go through all the available reports and print data as CSV
puts CSV::generate_line([
  'informe',
  'comunidad autónoma',
  'dosis Pfizer',
  'dosis Moderna',
  'dosis AstraZeneca',
  'dosis entregadas',
  'dosis administradas',
  '% sobre entregadas',
  'personas con al menos una dosis',
  'personas con pauta completa',
  'última vacuna registrada'
])
Dir['reports/*txt'].sort.each do |filename|
  extract_data(get_data_table(filename), filename)
end

