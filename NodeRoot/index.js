var gpio = require("pi-gpio")
var express = require("express")

var app = express()
var gpios = [7,11,12]

var blinkSpeed = 0
var blinkState = false

var waterfallIndex = 0
var waterfallSpeed = 0
var waterfallState = false

app.get('/', function (req, res) {
  var text = 'Hello, current time is '
  text += Date.now()
  res.send(text)
})

gpios.forEach( function (element) {
	gpio.close(element)
	gpio.open(element, "output", function(err) {
		console.log(err)
	})
	gpio.open(element, "input", function(err) {
		console.log(err)
	})
})

var toggle = function (gpioNumber, state, callback) {
	if (gpios.indexOf(gpioNumber) > -1) {
		gpio.write(gpioNumber, state ? 1 : 0, function() {
			callback("Turned led "  + (state ? "on" : "off"))
	  	})
	} else {
		callback("Wrong gpio: " + gpioNumber)
	}
}

var status = function (gpioNumber, callback) {
	if (gpios.indexOf(gpioNumber) > -1) {
		gpio.read(gpioNumber, function(err, value) {
			callback(value)
		})
	} else {
		callback(-1)
	}
}

var blink = function () {
	if (blinkSpeed <= 0) {
		blinkState = false
	} else {
		gpios.forEach( function (element) {
			status(element, function(status) {
				if(status != -1) {
					toggle(element, status == 0, function(text) {
						console.log(text)
					})
				} else {
					console.log("Error")
				}
			})
		})

		setTimeout(blink, blinkSpeed)
	}
}

var waterfall = function () {
	if (waterfallSpeed <= 0) {
		waterfallIndex = 0
		waterfallState = false
	} else {
		var currentGpio = gpios[waterfallIndex]
		var previousGpio = gpios[(waterfallIndex == 0) ? (gpios.length - 1) : (waterfallIndex - 1)]

		toggle(previousGpio, false, function(text) {
			console.log(text + previousGpio)
		})
		toggle(currentGpio, true, function(text) {
			console.log(text + currentGpio)
		})

		waterfallIndex = (waterfallIndex < gpios.length - 1) ? (waterfallIndex + 1) : 0
		console.log(waterfallIndex)

		setTimeout(waterfall, waterfallSpeed)
	}
}

app.get("/hello", function (req, res) {
	res.send(gpios)
})

app.get("/on:number", function (req, res) {
	toggle(Number(req.params.number), true, function(text) {
		console.log(text)
		res.send(text)
	})
})

app.get("/off:number", function (req, res) {
	toggle(Number(req.params.number), false, function(text) {
		console.log(text)
		res.send(text)
	})
})

app.get("/status", function (req, res) {
	var statusList = {}
	var count = gpios.length

	gpios.forEach( function (element) {
		status(element, function(status) {
			statusList["" + element] = status == 1
			count--;
			if(count == 0) {
				statusList.waterfall = waterfallSpeed != 0
				statusList.lightshow = blinkSpeed != 0
				res.send(statusList)
			}
		})
	})
})

app.get("/switch:number", function (req, res) {

	status(Number(req.params.number), function(status) {
		if(status != -1) {
			toggle(Number(req.params.number), status == 0, function(text) {
				console.log(text)
				res.send((status == 0 ? 1 : 0) + "")
			})
		} else {
			console.log("Error")
			res.send(status + "")
		}
	})
})

app.get("/lightshow:state", function (req, res) {
	var speed = Number(req.params.state)

	if (speed > 0) {
		blinkSpeed = speed
		if (!blinkState) {
			blinkState = true
			blink()
			waterfallSpeed = 0
			res.send("Blinking On")
		} else {
			res.send("Blinking Speed altered")
		}
	} else {
		blinkSpeed = speed
		res.send("Blinking Off")
	}
})

app.get("/waterfall:state", function (req, res) {
	var speed = Number(req.params.state)

	if (speed > 0) {
		waterfallSpeed = speed
		if (!waterfallState) {
			waterfallState = true
			waterfall()
			blinkSpeed = 0
			res.send("Waterfall On")
		} else {
			res.send("Waterfall Speed altered")
		}
	} else {
		waterfallSpeed = speed
		res.send("Waterfall Off")
	}
})



app.listen(3000, function () {
  console.log('Example app listening on port 3000!')
})
