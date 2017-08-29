const IOTA = require('iota.lib.js');

// Create IOTA instance with host and port as provider
var iota = new IOTA({
    'host': 'http://service.iotasupport.com',
    'port': 14265
});

// now you can start using all of the functions
iota.api.getNodeInfo((function(error, success) {
    if (error) {
        console.error(error);
    } else {
        console.log(success);
    }
}));

// you can also get the version
iota.version

