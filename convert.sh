# TODO: Iterate through *pdf, convert only if txt not found
pdftotext -enc UTF-8 -table reports/20200104.pdf

ruby parse.rb > data.csv