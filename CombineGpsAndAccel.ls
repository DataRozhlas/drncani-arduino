require! {
  fs
  'stats-lite':stats
}

accelData = fs.readFileSync "#__dirname/data/1442908846661-COM3.csv"
  .toString!
  .split "\n"
  .map (line) ->
    [time, ...values] = line.split "," .map parseInt _, 10
    altitude = 0
    for i in [1 til values.length]
      altitude += Math.abs values[i] - values[i - 1]
    samples = values.length
    {time, values, altitude, samples}

geoData = fs.readFileSync "#__dirname/data/track1.tsv"
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
currentGeoIndex = 0

for datum in accelData
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
  averageAltitude = altitude / samples
  variance = stats.variance points
  diff = maximum - minimum
  "#original\t#averageAltitude\t#variance\t#altitude\t#maximum\t#minimum\t#diff\t#samples"

out.unshift "fromTime\ttoTime\tlat\tlon\tspeed\taverageAltitude\tvariance\taltitude\tmaximum\tminimum\tdiff\tsamples"
fs.writeFileSync "#__dirname/data/track1-out.tsv", out.join "\n"
