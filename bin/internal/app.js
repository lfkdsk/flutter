var express = require('express');
var path = require('path');
var app = express();

function getIPAdress() {
    var interfaces = require('os').networkInterfaces();　　
    for (var devName in interfaces) {　　　　
        var iface = interfaces[devName];　　　　　　
        for (var i = 0; i < iface.length; i++) {
            var alias = iface[i];
            if (alias.family === 'IPv4' && alias.address !== '127.0.0.1' && !alias.internal) {
                return alias.address;
            }
        }　　
    }
}

var ip = getIPAdress();
var t1 = new Date().getTime();
app.use(express.static(__dirname));
 
var server = app.listen(8086, ip, function () {
    console.log("Flutter 动态化扫码地址为 http://%s:%s?timestamp=%s", ip, 8086, t1);
})