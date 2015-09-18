require! {
  fs
  xml2js:{parseString}
}
xml = fs.readFileSync "#__dirname/data/otresotest.gpx" .toString!
(err, result) <~ parseString xml
# result.gpx.wpt.length = 3
lastToTime = 0
out = for wpt, index in result.gpx.wpt
  lat = wpt.$.lat
  lon = wpt.$.lon
  timeString = wpt.time.0
  date = new Date timeString
  time = date.getTime!
  speed = wpt.extensions.0.vel.0
  nextTime = if result.gpx.wpt[index + 1]
    new Date result.gpx.wpt[index + 1].time.0 .getTime!
  else
    Date.now!
  fromTime = lastToTime
  toTime = Math.round (time + nextTime) / 2
  lastToTime = toTime
  [timeString, fromTime, toTime, lat, lon, speed].join "\t"

out.unshift "timeString\tfromTime\ttoTime\tlat\tlon\tspeed"
fs.writeFileSync do
  "#__dirname/data/test.tsv"
  out.join "\n"
