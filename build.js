const fs = require("fs-extra");

// Read compiled HTML
let html = fs.readFileSync("ui.html", "utf8");

// Read compiled CSS
let css = fs.readFileSync("styles.css", "utf8");

// Inject CSS into <style> tags
html = html.replace("</head>", `<style>${css}</style></head>`);

// Save the final bundled file
fs.writeFileSync("ui.html", html, "utf8");

console.log("✅ Successfully bundled CSS into ui.html!");