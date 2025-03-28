document.getElementById("apply").addEventListener "click", ->
  horizontalSpacing = parseInt(document.getElementById("horizontalSpacing")?.value, 10) || 0
  verticalSpacing = parseInt(document.getElementById("verticalSpacing")?.value, 10) || 0

  console.log "📤 Sending to Figma:", { horizontalSpacing, verticalSpacing }

  parent.postMessage
    pluginMessage:
      type: "apply-spacing"
      horizontalSpacing: horizontalSpacing
      verticalSpacing: verticalSpacing
  , "*"