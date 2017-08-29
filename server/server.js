var appPort = process.env.PORT || 80; // $ PORT=3000 node server.js
var express = require('express');
var bodyParser = require('body-parser');
var IOTA = require('iota.lib.js');
const base91 = require('node-base91');

var app = express();
var iota = new IOTA({
	'host': 'http://service.iotasupport.com',
	'port': 14265
});

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

app.set('json spaces', 40);

app.get('/', function (req, res){
	res.status(200).send('Hello, this is the Peakon server. IOTA version: ' + iota.version);
});

app.post('/', function (req, res) {
	// expected JSON payload in req.body
	/*
	{
		"peripheralData": "0x1700f4080",
		"peripheralIdentifier": "9F76EE86-872D-407D-9C73-BA4DB6F4C468",
		"urlString": "https://ruu.vi/#BEQgAMO0D",
		"targetWallet": "abcde"
	}
	*/

	let incominData = req.body;
	let errorData = {"reason": null};
	// console.log('incominData', incominData);

	// check if this contains all necessary data
	if (!incominData.peripheralData || !incominData.peripheralIdentifier || !incominData.targetWallet) {
		errorData.reason = 'missing data';
	}

	if (errorData.reason) {
		// send error response
		res.status(500).json(errorData);
		return;
	}

	// parse weather data from urlString
	incominData.weatherData = null;
	if (incominData.urlString) {
		incominData.weatherData = parseWeatherData(incominData.urlString.replace('https://ruu.vi/#', ''));
	}


	// send success response
	res.status(200).json(incominData);

});

app.listen(appPort);
console.log('Peakon server listens on port ' + appPort);















// stolen from https://ruu.vi/#BEQgAMO0D - hope that's fine!
function parseWeatherData (variables) {
	if(variables.length === 9){
		variables += "...";
	}

	var decoded   = base91.decode(variables); // console.log("91 : " + decoded);

	// var decoded64 = base64_decode(variables); console.log("64 : " + decoded64);
	var b = new Buffer(variables, 'base64')
	var decoded64 = b.toString();


	/*
	0:   uint8_t     format;          // (0x01 = realtime sensor readings in base91)
	1:   uint8_t     humidity;        // one lsb is 0.5%
	2-3: uint16_t    temperature;     // Signed 8.8 fixed-point notation.
	4-5: uint16_t    pressure;        // (-50kPa)
	6-7: uint16_t    time;            // seconds (now from reset, later maybe from last movement)
	*/
	var format = decoded64[0];

	let temp = 0;
	let air_pressure = 0;
	let humidity = 0;

	if(2 !== format && 4 !== format){
		humidity = decoded[1] * 0.5;
		//The bytes are swaped during the encoding, thus read byte 3 as first byte, byte 2 as 2nd
		//Same goes for pressure and time
		var uTemp = (((decoded[3] & 127) << 8) | decoded[2]);
		var tempSign = (decoded[3] >> 7) & 1;
		temp = tempSign === 0 ? uTemp/256.0 : -1 * uTemp/256.0;
		air_pressure = ((decoded[5] << 8) + decoded[4]) + 50000; 
	}
	/*
	0:   uint8_t     format;          // (0x02 = realtime sensor readings in base64)
	1:   uint8_t     humidity;        // one lsb is 0.5%
	2-3: uint16_t    temperature;     // Signed 8.8 fixed-point notation.
	4-5: uint16_t    pressure;        // (-50kPa)
	*/
	else {
		humidity = decoded64[1] * 0.5;
		var uTemp = (((decoded64[2] & 127) << 8) | decoded64[3]);
		var tempSign = (decoded64[2] >> 7) & 1;
		temp = tempSign === 0 ? uTemp/256.0 : -1 * uTemp/256.0;
		air_pressure = ((decoded64[4] << 8) + decoded64[5]) + 50000;
	}

	return {
		tempC: Math.round(temp),
		tempF: Math.round(temp * 1.8 + 32),
		humidityPercent: Math.round(humidity),
		airPressure: Math.round(air_pressure/100)
	};
}
