require! {
  fs
  'stats-lite':stats
}
wheel = "L"
source = if wheel == "R" then "right" else "left"
console.log "Loading accel data"
accelData = fs.readFileSync "#__dirname/data-combine/#{source}.csv"
  .toString!
  .split "\n"
  .map (line) ->
    [time, ...values] = line.split "," .map parseInt _, 10
    altitude = 0
    for i in [1 til values.length]
      altitude += Math.abs values[i] - values[i - 1]
    samples = values.length
    {time, values, altitude, samples}


console.log "Loading geo data"
geoData = fs.readFileSync "#__dirname/data-combine/track-out.tsv"
  .toString!
  .split "\n"
geoData.shift!
geoData .= map (line) ->
  original = line
  toTime = parseInt do
    line.split "\t" .1
    10
  altitude = 0
  samples = 0
  points = []
  minimum = Infinity
  maximum = -Infinity
  {original, toTime, altitude, samples, points, minimum, maximum}

console.log "Collating"
currentGeoIndex = 0
for datum, index in accelData
  while datum.time > geoData[currentGeoIndex].toTime
    currentGeoIndex++
    if geoData[currentGeoIndex] is void
      console.error "Out of bounds for time #{datum.time}"
  geoData[currentGeoIndex].altitude += datum.altitude
  geoData[currentGeoIndex].samples += datum.samples
  for point in datum.values
    if point < geoData[currentGeoIndex].minimum
      geoData[currentGeoIndex].minimum = point
    if point > geoData[currentGeoIndex].maximum
      geoData[currentGeoIndex].maximum = point
    geoData[currentGeoIndex].points.push point

out = for {original, altitude, samples, points, maximum, minimum} in geoData
  # averageAltitude = altitude / samples
  if points.length
    variance = stats.variance points
    diff = maximum - minimum
  else
    variance = diff = maximum = minimum =  ""
  # continue if samples == 0
  "#original\t#variance\t#altitude\t#maximum\t#minimum\t#diff\t#{points.length}"

out.unshift "fromTime\ttoTime\tlat\tlon\tspeed\tvarianceR\taltitudeR\tmaximumR\tminimumR\tdiffR\tsamplesR\tvarianceL\taltitudeL\tmaximumL\tminimumL\tdiffL\tsamplesL"
console.log "Writing"
fs.writeFileSync "#__dirname/data-combine/track-out-both.tsv", out.join "\n"
console.log "Done"
