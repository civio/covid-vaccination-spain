# Fetch today's report...
today=$(date '+%Y%m%d')
filename="reports/$today.pdf"
wget -O $filename https://www.mscbs.gob.es/profesionales/saludPublica/ccayes/alertasActual/nCov/documentos/Informe_GIV_comunicacion_$today.pdf

# ...and convert it to text.
pdftotext -enc UTF-8 -table $filename
