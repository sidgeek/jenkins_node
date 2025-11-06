"use strict";
const http = require("http");
const app = http.createServer((req, res) => {
  res.end("hello world3");
});
app.listen(3009, "0.0.0.0");