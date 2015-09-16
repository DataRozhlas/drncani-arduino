require! {
  fs
  serialport:{SerialPort}
}
intro = [0xff 0xff 0x00 0x00]
readAccelPort = (port) ->
  serial = new SerialPort port, baudrate: 115200
  <~ serial.on \open
  console.log "Open"
  overflow = null
  currentData = []
  introPosition = 0
  stream = fs.createWriteStream "#__dirname/data/#{Date.now!}-#port.csv"
  absoluteStream = fs.createWriteStream "#__dirname/data/#{Date.now!}-#port.bin"
  altitude = 0
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
    for i in [1 til accels.length]
      altitude += Math.abs accels[i] - accels[i - 1]
    stream.write "#{Date.now!},#{accels.join ','}\n"
  reportAltitude = ->
    console.log port, altitude
    altitude := 0
  setInterval reportAltitude, 500
readGpsPort = (port) ->
  serial = new SerialPort port, baudrate: 9600
  stream = fs.createWriteStream "#__dirname/data/#{Date.now!}-#{port}-gps.csv"
  <~ serial.on \open
  console.log "Open"
  serial.on \data (data) ->
    data = data.toString!replace /[\n\r]/g ""
    stream.write "#{Date.now!}|#{data}\n"

readAccelPort "COM3"
readAccelPort "COM9"
readGpsPort "COM8"
