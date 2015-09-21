require! {
  fs
  serialport:{SerialPort}
  nmea
}
intro = [0xff 0xff 0x00 0x00]
reports = []

readAccelPort = (port) ->
  serial = new SerialPort port, baudrate: 115200
  <~ serial.on \open
  console.log "Open"
  overflow = null
  currentData = []
  introPosition = 0
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
      if octet == intro[introPosition]
        introPosition++
        if introPosition >= intro.length
          processData!
          introPosition := 0
          currentData.length = 0
      else
        introPosition := 0

  processData = ->
    dataWithoutIntro = currentData.slice 0, -4
    if dataWithoutIntro.length != 32
      console.log "Error in transport"
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
    report.altitudeAvg = Math.round report.altitude / report.samples
    stream.write "#{Date.now!},#{accels.join ','}\n"


readGpsPort = (port) ->
  serial = new SerialPort port, baudrate: 115200
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
        parsed = nmea.parse it
        switch parsed.type
        | 'geo-position'
          report.latitude = parsed.lat || null
          report.longitude = parsed.lon || null
          report.time = parsed.timestamp
        | 'track-info'
          report.speed = parsed.speedKmph
    data = data.toString!replace /[\n\r]/g ""
    stream.write "#{Date.now!}|#{data}\n"

readAccelPort "COM3"
readAccelPort "COM4"
readGpsPort "COM8"

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



setInterval report, 250
