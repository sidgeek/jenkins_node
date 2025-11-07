"use strict";
const http = require("http");
const app = http.createServer((req, res) => {
  res.end("hello world");
});
app.listen(3006, "0.0.0.0");