const fs = require("fs");
const path = require("path");

module.exports = (req, res) => {
  const file = path.join(__dirname, "..", "public", "cloudfix.ps1");
  const content = fs.readFileSync(file, "utf8");
  res.setHeader("Content-Type", "text/plain; charset=utf-8");
  res.setHeader("Cache-Control", "no-cache");
  // Prepend UTF-8 BOM so PowerShell 5.1's irm detects encoding correctly
  res.send("﻿" + content);
};
