fs = require "fs-extra"
{ execSync } = require "child_process"
path = require "path"
debounce = require "lodash.debounce"

# Store last file modification timestamps
fileTimestamps = {}

# Function to compile all CoffeeScript files
compileCoffeeScript = ->
    try
        console.log "Compiling CoffeeScript..."
        execSync "coffee -c -o dist/ src/"
        console.log "CoffeeScript compiled successfully."
    catch error
        console.error "❌ CoffeeScript compilation failed:", error.message
        process.exit 1

# Function to bundle UI files
bundleUI = ->
    try
        console.log "Bundling UI components..."
        execSync "pug src/ui.pug --out dist/"
        console.log "Pug compiled to dist/ui.html"
        execSync "sass src/styles.sass dist/styles.css"
        console.log "SASS compiled to dist/styles.css"

        html = fs.readFileSync "dist/ui.html", "utf8"
        css = fs.readFileSync "dist/styles.css", "utf8"
        bundledHtml = html.replace "</head>", "<style>#{css}</style></head>"
        fs.writeFileSync "dist/ui.html", bundledHtml, "utf8"

        console.log "Successfully bundled UI into dist/ui.html!"
    catch error
        console.error "❌ UI bundling failed:", error.message
        process.exit 1

# Function to concatenate JavaScript files
concatenateJavaScript = ->
    try
        console.log "Concatenating JavaScript files..."
        jsFiles = fs.readdirSync("dist").filter (file) ->
            file.endsWith(".js") and file isnt "plugin.js"

        concatenatedContent = jsFiles.map (file) ->
            fs.readFileSync(path.join("dist", file), "utf8")
        .join("\n")

        fs.writeFileSync "dist/plugin.js", concatenatedContent, "utf8"
        console.log "JavaScript files concatenated into dist/plugin.js"
    catch error
        console.error "❌ JavaScript concatenation failed:", error.message
        process.exit 1

# Function to perform the full build process
build = ->
    console.log "Running full build process..."
    compileCoffeeScript()
    bundleUI()
    concatenateJavaScript()
    console.log "✅ Build complete."

# Initial build
build()

# Debounced build function to prevent redundant triggers
debouncedBuild = debounce(build, 500)

# Function to watch for file changes in the src directory
watchFiles = ->
    console.log "Watching for changes in the src directory... Press Ctrl+C to stop."

    fs.watch "src", { recursive: true }, (eventType, filename) ->
        if filename
            filePath = path.join("src", filename)

            try
                stats = fs.statSync(filePath)
                modifiedTime = stats.mtimeMs

                # Prevent unnecessary rebuilds by checking for actual file content modifications
                if fileTimestamps[filePath] and fileTimestamps[filePath] == modifiedTime
                    return # Skip rebuild if the file hasn't actually changed

                fileTimestamps[filePath] = modifiedTime
                console.log "Detected changes in #{filename}. Scheduling rebuild..."
                debouncedBuild()

            catch error
                console.error "❌ Error reading file:", error.message

watchFiles()