const fs = require("fs");
const path = require("path");

module.exports = (req, res) => {
  const file = path.join(__dirname, "..", "public", "install.ps1");
  const content = fs.readFileSync(file, "utf8");
  res.setHeader("Content-Type", "text/plain; charset=utf-8");
  res.setHeader("Cache-Control", "no-cache");
  res.send(content);
};
