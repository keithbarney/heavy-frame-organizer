// Show the UI with an initial size
figma.showUI(__html__, { width: 400, height: 200 });

// Listen for messages from the UI
figma.ui.onmessage = (msg) => {
    console.log("📥 Received message:", msg);

    if (msg.type === "apply-spacing") {
        const { horizontalSpacing, verticalSpacing } = msg;

        // Save settings for future sessions
        figma.clientStorage.setAsync("spacingSettings", { horizontalSpacing, verticalSpacing });

        // Organize all frames on the page
        organizeFrames(horizontalSpacing, verticalSpacing);
    } else if (msg.type === "resize") {
        // Resize the plugin window dynamically
        const { width, height } = msg;
        figma.ui.resize(width, height);
        console.log(`📏 Resized UI to ${width}x${height}`);
    }
};

// Force a resize after the UI loads
setTimeout(() => {
    figma.ui.postMessage({ type: "request-resize" });
}, 100);

// Function to organize all frames on the page
function organizeFrames(hSpacing, vSpacing) {
    console.log(`🛠️ Organizing Frames: H=${hSpacing}, V=${vSpacing}`);

    // Get all frames on the current page
    const frames = figma.currentPage.children.filter(node => node.type === "FRAME");

    if (frames.length === 0) {
        figma.notify("⚠️ No frames found on the page.");
        return;
    }

    // Sort frames alphabetically by name
    frames.sort((a, b) => a.name.localeCompare(b.name));

    // Track parent frames for positioning
    const parentFrames = {};
    const lastSubFrameY = {}; // Keeps track of the last sub-frame's Y position per parent

    frames.forEach(frame => {
        const isSubFrame = frame.name.includes("/");

        if (isSubFrame) {
            // Sub-frame detected → Find parent
            const parentName = frame.name.split("/")[0];

            if (parentFrames[parentName]) {
                // Determine proper Y position based on previous sub-frame
                const lastY = lastSubFrameY[parentName] || parentFrames[parentName].y;

                frame.x = parentFrames[parentName].x;
                frame.y = lastY + parentFrames[parentName].height + vSpacing;

                // Update last Y position for stacking sub-frames correctly
                lastSubFrameY[parentName] = frame.y;
            }
        } else {
            // Top-level frame → Position it horizontally
            const prevFrame = Object.values(parentFrames).pop();

            frame.x = prevFrame ? prevFrame.x + prevFrame.width + hSpacing : 0;
            frame.y = 0;

            // Store reference for sub-frames
            parentFrames[frame.name] = frame;
            lastSubFrameY[frame.name] = frame.y; // Initialize parent’s last Y position
        }

        console.log(`✅ Positioned Frame: ${frame.name} at (${frame.x}, ${frame.y})`);
    });

    figma.notify(`✅ Frames Organized`);
}