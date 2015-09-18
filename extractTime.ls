require! {
  fs
}
timeFrom = 1442492093500
timeTo   = 1442492094500
accelData = fs.readFileSync "#__dirname/data/1442490640610-COM3.csv"
  .toString!
  .split "\n"
  .map (line) ->
    [time, ...values] = line.split "," .map parseInt _, 10
    altitude = 0
    for i in [1 til values.length]
      altitude += Math.abs values[i] - values[i - 1]
    samples = values.length
    time = parseInt time, 10
    {time, values, altitude, samples}
  .filter ->
    timeFrom <= it.time <= timeTo
  .reduce do
    (prev, curr) ->
      prev ++ curr.values
    []

console.log accelData.join "\n"
