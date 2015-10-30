require! fs

gps = fs.readFileSync "#__dirname/data-combine/gps.csv"
  .toString!
  .split "\n"
  .filter -> it.length > 2
out = fs.createWriteStream "#__dirname/data-combine/gps-clean.csv"
c = 0
nmeaBuf = ""
nmeaStart = 0
for line in gps
  [time, data] = line.split "|"
  data .= replace /[\n\r]/g ''
  time = parseInt time, 10
  for char in data
    if char == "$"
      # out.write "#{time}|#{nmeaBuf}\n"
      process.stdout.write "#{time}|#{nmeaBuf}\n"
      # console.log "#{time}|#{nmeaBuf}"
      nmeaBuf = "$"
      nmeaStart = time
    else if char == "\n" or char == "\r"
      continue
    else
      nmeaBuf += char
