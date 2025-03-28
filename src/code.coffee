# Ensure the UI is properly loaded with adjustable size
figma.showUI(__html__, { width: 400, height: 400 })

# Load previous spacing values from client storage
loadSpacingValues = ->
	Promise.all([
		figma.clientStorage.getAsync("horizontalSpacing"),
		figma.clientStorage.getAsync("verticalSpacing")
	]).then(([storedHorizontal, storedVertical]) ->
		horizontalSpacing = storedHorizontal || 0
		verticalSpacing = storedVertical || 0
		figma.ui.postMessage({ type: "load-spacing", horizontalSpacing, verticalSpacing })
	).catch (error) ->
		console.error "Error loading spacing values:", error

loadSpacingValues()

# Listen for messages from the UI
figma.ui.onmessage = (msg) ->
	console.log "Message received from UI:", msg

	if msg?.type == "organize-frames"
		verticalSpacing = parseFloat(msg?.verticalSpacing) || 0
		horizontalSpacing = parseFloat(msg?.horizontalSpacing) || 0

		# Save values asynchronously
		Promise.all([
			figma.clientStorage.setAsync("horizontalSpacing", horizontalSpacing).catch (error) ->
				console.error "Error saving horizontal spacing:", error,
			figma.clientStorage.setAsync("verticalSpacing", verticalSpacing).catch (error) ->
				console.error "Error saving vertical spacing:", error
		])

		organizeFrames(verticalSpacing, horizontalSpacing)

# Function to organize Figma elements
organizeFrames = (verticalSpacing, horizontalSpacing) ->
	console.log "Scanning elements on the Figma page..."

	mainComponent = null
	subComponents = []
	sections = []

	# Identify main component, sub-components, and sections
	for node in figma.currentPage.children
		console.log "Checking:", node.name, "Type:", node.type

		if node.type == "COMPONENT" or node.type == "COMPONENT_SET"
			if node.name.startsWith(".")
				subComponents.push(node) # Store sub-components
			else if not mainComponent
				mainComponent = node # Set the first non-prefixed component as main

		if node.type == "SECTION"
			sections.push(node) # Store sections

	# Move the main component to (0,0)
	if mainComponent
		console.log "Setting main component:", mainComponent.name, "to (0,0)"
		mainComponent.x = 0
		mainComponent.y = 0

		# Move sub-components below the main component
		yOffset = mainComponent.y + mainComponent.height + verticalSpacing
		for subComponent in subComponents.sort((a, b) -> a.name.localeCompare(b.name))
			console.log "Moving sub-component:", subComponent.name, "to (0,", yOffset, ")"
			subComponent.x = mainComponent.x # Keep x aligned with main component
			subComponent.y = yOffset
			yOffset += subComponent.height + verticalSpacing

		# Move sections to the right of the main component
		xOffset = mainComponent.x + mainComponent.width + horizontalSpacing
		for section in sections.sort((a, b) -> a.name.localeCompare(b.name))
			console.log "Moving section:", section.name, "to (", xOffset, ",", mainComponent.y, ")"
			section.x = xOffset
			section.y = mainComponent.y
			xOffset += section.width + horizontalSpacing

	else
		console.log "No main component found. Sub-components and sections will not be moved."

	# Refresh the Figma UI
	figma.currentPage.selection = if mainComponent then [mainComponent].concat(subComponents).concat(sections) else subComponents.concat(sections)
	figma.viewport.scrollAndZoomIntoView(figma.currentPage.selection)

	console.log "Reorganization complete!"
	figma.notify("Main, sub-components, and sections arranged!")
	figma.closePlugin()