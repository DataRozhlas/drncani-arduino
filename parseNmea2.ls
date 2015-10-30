require! {
  fs
  nmea
}
lines = fs.readFileSync "#__dirname/data-combine/gps-clean.csv" .toString!
  .split "\n"

records = for line in lines
  [time, data] = line.split "|"
  continue unless data
  time = parseInt time, 10
  {time, data}
records .= filter -> it.data.length > 1
validRecord = records.0
for record in records
  try
    parsed = nmea.parse record.data
    if parsed.type == 'geo-position'
      validRecord = record
    switch parsed.type
      | 'geo-position', 'nav-info'
        if parsed.lat
          validRecord.latitude = parseInt parsed.lat.substr 0, 2
          validRecord.latitude += 1/60 * parseFloat parsed.lat.substr 2
        else
          validRecord.latitude = null
        if parsed.lon
          validRecord.longitude = parseInt parsed.lon.substr 0, 3
          validRecord.longitude += 1/60 * parseFloat parsed.lon.substr 3
        else
          validRecord.longitude = null
        validRecord.timestamp = parsed.timestamp
      | 'track-info'
        validRecord.speed = parsed.speedKmph
records .= filter -> it.latitude and it.longitude
console.log records.length

lastToTime = 0
currentKm = 0
kmDir = 1
out = for record, index in records
  lat = record.latitude
  lon = record.longitude
  time = record.time
  speed = parseFloat record.speed
  nextTime = if records[index + 1]
    records[index + 1].time
  else
    Date.now!
  fromTime = lastToTime
  toTime = Math.round (time + nextTime) / 2
  if index == 10165
    currentKm := 0
  else if index == 99705
    currentKm := 193.5
    kmDir := -1
  seconds = (toTime - fromTime) / 1000
  if fromTime > 0
    distance = speed * seconds / 3600
    currentKm += distance * kmDir
  lastToTime = toTime
  # lat .= toString!
  # lon .= toString!
  # lat .= substr 0, 10 if lat.length > 10
  # lon .= substr 0, 10 if lon.length > 10
  [fromTime, toTime, lat, lon, speed, currentKm.toFixed 3].join "\t"
console.log out.length
out.unshift "fromTime\ttoTime\tlat\tlon\tspeed\tkm"
fs.writeFileSync do
  "#__dirname/data-combine/track.tsv"
  out.join "\n"
