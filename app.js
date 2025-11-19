"use strict";
const http = require("http");
const app = http.createServer((req, res) => {
  // this is feature
  res.end("hello world2");
});
app.listen(3006, "0.0.0.0");