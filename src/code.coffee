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

	mainComponents = []
	subComponents = []
	sections = []

	# Identify main component, sub-components, and sections
	for node in figma.currentPage.children
		console.log "Checking:", node.name, "Type:", node.type

		if node.type == "COMPONENT" or node.type == "COMPONENT_SET"
			if node.name.startsWith(".")
				subComponents.push(node) # Store sub-components
			else
				mainComponents.push(node) # Store main components

		if node.type == "SECTION"
			sections.push(node) # Store sections

	# Move the main components
	if mainComponents.length > 0
		console.log "Organizing #{mainComponents.length} main components"
		allSelected = []
		xOffset = 0
		maxColumnHeight = 0

		for mainComponent in mainComponents.sort((a, b) -> a.name.localeCompare(b.name))
			console.log "Setting main component:", mainComponent.name, "to (#{xOffset}, 0)"
			mainComponent.x = xOffset
			mainComponent.y = 0
			allSelected.push(mainComponent)

			yOffset = mainComponent.height + verticalSpacing

			relatedSubComponents = subComponents.filter (sub) ->
				sub.name.trim().startsWith(".#{mainComponent.name.trim()}")
			for subComponent in relatedSubComponents.sort((a, b) -> a.name.localeCompare(b.name))
				console.log "Moving sub-component:", subComponent.name, "to (#{xOffset},#{yOffset})"
				subComponent.x = xOffset
				subComponent.y = yOffset
				yOffset += subComponent.height + verticalSpacing
				allSelected.push(subComponent)

			columnHeight = yOffset
			if columnHeight > maxColumnHeight then maxColumnHeight = columnHeight

			xOffset += mainComponent.width + horizontalSpacing

		sectionXOffset = xOffset
		sectionYOffset = 0
		for section in sections.sort((a, b) -> a.name.localeCompare(b.name))
			console.log "Moving section:", section.name, "to (#{sectionXOffset},#{sectionYOffset})"
			section.x = sectionXOffset
			section.y = sectionYOffset
			sectionYOffset += section.height + verticalSpacing
			allSelected.push(section)

	else
		console.log "No main components found. Sub-components and sections will not be moved."

	# Refresh the Figma UI
	figma.currentPage.selection = allSelected
	figma.viewport.scrollAndZoomIntoView(figma.currentPage.selection)

	console.log "Reorganization complete!"
	figma.notify("Main, sub-components, and sections arranged!")
	figma.closePlugin()