const appPort = process.env.PORT || 80; // $ PORT=3000 node server.js
const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const IOTA = require('iota.lib.js');
const base91 = require('node-base91');

// tourist seed: LYCHWQDOEDUQIJDGTCLIFJPDQDHLXHWAWZKARVWKRPAVTMDHTEKWCXIKR9YXXXOGUSJXWLQHJLGTBEXJQ
// tourist wallet: KR9EZO9VFSNYTOEPQBIOVYHGBJQGHZQICDDBYIDTBBCHBZPCGXPUYMXXYVBQHBDXTVSKADTJRVINZXK9XHTRKLEIP9

// express app
var app = express();

// IOTA connect
var iota = new IOTA({
	'host': 'http://35.158.244.116',
	'port': 14700
});

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

app.get('/', function (req, res){
	let packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
	res.status(200).send('Hello, this is the Peakon server version ' + packageJson.version + '. IOTA version ' + iota.version);
});

app.get('/beacons', function (req, res){
	let beaconData = JSON.parse(fs.readFileSync('wallets.json', 'utf8'));
	let beaconOut = {};
	for (let i in beaconData) {
		beaconOut[i] = {};
		beaconOut[i].beaconName = beaconData[i].beaconname;
		beaconOut[i].beaconOwner = beaconData[i].beaconowner;
		beaconOut[i].beaconReward = beaconData[i].reward;
		beaconOut[i].beaconUrl = beaconData[i].wikipediaurl;

		console.log(beaconOut[i]);
	}
	res.status(200).send(beaconOut);
});

app.post('/', function (req, res) {
	// expected JSON payload in req.body
	/*
	{
		"peripheralIdentifier": "9F76EE86-872D-407D-9C73-BA4DB6F4C468",
		"urlString": "https://ruu.vi/#BEQgAMO0D",
		"targetWallet": "abcde"
	}
	*/

	let incominData = req.body;
	console.log(Date.now() + ': incominData', JSON.stringify(incominData));

	let outgoingData = {};
	let errorData = {"reason": null};
	// console.log('incominData', incominData);

	// check if this contains all necessary data
	if (!incominData.peripheralIdentifier) { //  || !incominData.targetWallet
		errorData.reason = 'missing data';
	}

	// more error checks

	// exit early if something's wrong
	if (errorData.reason) {
		// send error response
		res.status(500).json(errorData);
		return;
	}

	// get beacon wallet from "DB"
	var beaconWallets = JSON.parse(fs.readFileSync('wallets.json', 'utf8'));
	var beaconKey = incominData.peripheralIdentifier;
	console.log('beaconKey', beaconKey);
	if (typeof beaconWallets[beaconKey] == 'undefined') {
		// send error response
		errorData.reason = 'beacon not found';
		res.status(500).json(errorData);
		return;
	}

	outgoingData.beaconName = beaconWallets[beaconKey].beaconname;
	outgoingData.beaconOwner = beaconWallets[beaconKey].beaconowner;
	outgoingData.beaconReward = beaconWallets[beaconKey].reward;
	outgoingData.beaconUrl = beaconWallets[beaconKey].wikipediaurl;

	// parse weather data from urlString
	outgoingData.weatherData = null;
	if (incominData.urlString) {
		outgoingData.weatherData = parseWeatherData(incominData.urlString.replace('https://ruu.vi/#', ''));
	}

	// if we have a targetWallet in incominData we'll initiate the transfer
	if (typeof incominData.targetWallet !== 'undefined') {

		res.status(200).json({
			"success": true
		});

	} else {
		// otherwise just send back 
		res.status(200).json(outgoingData);
	}

});

app.listen(appPort);
console.log('Peakon server listens on port ' + appPort);




// // dev / debug
let sourceSeed = "LYCHWQDOEDUQIJDGTCLIFJPDQDHLXHWAWZKARVWKRPAVTMDHTEKWCXIKR9YXXXOGUSJXWLQHJLGTBEXJQ";

// iota.api.sendTransfer();

// iota.api.getNewAddress(seedNow, {
// 		"security": 2
// 	}, (err, result) => {
// 		console.log('getNewAddress(%s) result:', seedNow, err, result);
// 	}
// );

// iota.api.getAccountData(seedNow, {
// 		"start": 0,
// 		"end": 20,
// 		"security": 2
// 	}, (err, result) => {
// 		console.log('getAccountData(%s) result:', seedNow, err, result);
// 	}
// );

// console.log('getAccountData() done');










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
