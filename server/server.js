var express = require('express');
var bodyParser = require('body-parser');
var app = express();

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

app.set('json spaces', 40);

app.get('/', function (req, res){
  res.status(200).send('hello, this is the peakon server');
});

app.post('/', function (req, res) {
  // res.status(200).json({ response: 'yes' });
  // res.status(404).json({ response: 'no' });
  res.status(200).json(req.body);
  console.log(req.body);
})

app.listen(3000);
