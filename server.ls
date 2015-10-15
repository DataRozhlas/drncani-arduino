require! {
  fs
  serialport:{SerialPort}
  nmea
  sse:SSE
  http
}
intro = [0xff 0xff 0x00 0x00]
reports = []
readAccelPort = (port) ->
  serial = new SerialPort port, baudrate: 57600
  <~ serial.on \open
  console.log "Open"
  overflow = null
  currentData = []
  stream = fs.createWriteStream "#__dirname/data/#{Date.now!}-#port.csv"
  absoluteStream = fs.createWriteStream "#__dirname/data/#{Date.now!}-#port.bin"
  report =
    port: port
    reset: ->
      @altitude = 0
      @altitudeAvg = 0
      @samples = 0
      @max = -Infinity
      @min = Infinity

  report.reset!
  reports.push report
  serial.pipe absoluteStream
  serial.on \data (data) ->
    for octet in data
      currentData.push octet
      last4 = currentData.slice -4
      for value, index in last4
        if intro[index] != value
          break
      if index == intro.length - 1
        processData!
        currentData.length = 0

  processData = ->
    dataWithoutIntro = currentData.slice 0, -4
    if dataWithoutIntro.length != 32
      console.log "Error in transport: #{dataWithoutIntro.length}"
      console.log dataWithoutIntro
      return

    buffer = new Buffer dataWithoutIntro
    accels = for i in [0 til buffer.length by 2]
      acc = buffer.readInt16BE i
      report.max = acc if acc > report.max
      report.min = acc if acc < report.min
      acc
    for i in [1 til accels.length]
      report.altitude += Math.abs accels[i] - accels[i - 1]
      report.samples++
    report.altitudeAvg = (report.altitude / report.samples).toFixed 2
    stream.write "#{Date.now!},#{accels.join ','}\n"


readGpsPort = (port) ->
  serial = new SerialPort port, baudrate: 57600
  rawStream = fs.createWriteStream "#__dirname/data/#{Date.now!}-#{port}-gps.bin"
  stream = fs.createWriteStream "#__dirname/data/#{Date.now!}-#{port}-gps.csv"
  report =
    port: port
    reset: ->
      @latitude = null
      @longitude = null
      @speed = null
      @time = null
  report.reset!
  reports.push report
  <~ serial.on \open
  console.log "Open"
  serial.pipe rawStream
  serial.on \data (data) ->
    lines = data
      .toString!
      .split "\n"
      .filter ->
        it.0 == "$" and "$GPGSV" != it.substr 0, 6
      .forEach ->
        try
          parsed = nmea.parse it
          switch parsed.type
          | 'geo-position', 'nav-info'
            if parsed.lat
              report.latitude = parseInt parsed.lat.substr 0, 2
              report.latitude += 1/60 * parseFloat parsed.lat.substr 2
            else
              report.latitude = null
            if parsed.lon
              report.longitude = parseInt parsed.lon.substr 0, 3
              report.longitude += 1/60 * parseFloat parsed.lon.substr 3
            else
              report.longitude = null
            report.time = parsed.timestamp
          | 'track-info'
            report.speed = parsed.speedKmph
    data = data.toString!replace /[\n\r]/g ""
    stream.write "#{Date.now!}|#{data}\n"

readAccelPort "COM3"
readAccelPort "COM7"
readGpsPort "COM6"

report = ->
  out = []
  for report in reports
    reportOut = {}
    out.push reportOut
    for key, value of report
      continue if key == "reset"
      process.stdout.write "#key: #value\t"
      reportOut[key] = value
    report.reset!
    process.stdout.write "\n"
    reportOut
  process.stdout.write "\n"
  reportOutput JSON.stringify out

reportOutput = (data) ->
  clients.forEach -> it.send data


setInterval report, 250

clients = []
server = http.createServer (req, res) ->
  console.log "Normal request, shouldn't happen"
  res.writeHead do
    * 200
    * "OK"
    * "Content-type": "text/plain"
      "Access-Control-Allow-Origin": "*"

  res.end!

<~ server.listen 8080
sse = new SSE server
console.log "Listening, probably"
sse.on \connection (client) ->
  clients.push client
  console.log "+1 = #{clients.length}"
  client.on \close ->
    index = clients.indexOf client
    return if index == -1
    clients.splice index, 1
    console.log "-1 = #{clients.length}"
