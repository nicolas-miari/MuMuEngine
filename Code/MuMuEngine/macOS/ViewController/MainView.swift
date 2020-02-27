//
//  MainView.swift
//  MuMuEngine
//
//  Created by Nicolás Miari on 2019/04/12.
//  Copyright © 2019 Nicolás Miari. All rights reserved.
//

import Cocoa

public class MainView: NSView {

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    // MARK: - Mouse Input

    // Based on: https://stackoverflow.com/a/41878227/433373
    var trackingArea : NSTrackingArea?

    // Based on: https://stackoverflow.com/a/41878227/433373
    override public func updateTrackingAreas() {
        if trackingArea != nil {
            self.removeTrackingArea(trackingArea!)
        }
        let options : NSTrackingArea.Options =
            [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow]
        trackingArea = NSTrackingArea(rect: self.bounds, options: options,
                                      owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }

    public override func mouseDown(with event: NSEvent) {
        var location = event.locationInWindow
        location.x -= bounds.width / 2
        location.y -= bounds.height / 2

        Runtime.shared.mouseDown(at: location)
    }

    public override func mouseMoved(with event: NSEvent) {
        var location = event.locationInWindow
        location.x -= bounds.width / 2
        location.y -= bounds.height / 2

        Runtime.shared.mouseMoved(to: location)
    }

    public override func mouseUp(with event: NSEvent) {
        var location = event.locationInWindow
        location.x -= bounds.width / 2
        location.y -= bounds.height / 2

        Runtime.shared.mouseUp(at: location)
    }

    public override func mouseDragged(with event: NSEvent) {
        var location = event.locationInWindow
        location.x -= bounds.width / 2
        location.y -= bounds.height / 2

        Runtime.shared.mouseDragged(to: location)
    }

    // MARK: - Keyboard Input

    public override var acceptsFirstResponder: Bool {
        return true
    }

    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let retVal = super.performKeyEquivalent(with: event)
        return retVal
    }

    public override func keyDown(with event: NSEvent) {
        let keyCode = Int(event.keyCode)
        Runtime.shared.handleKey(down: true, code: keyCode)
    }

    public override func keyUp(with event: NSEvent) {
        let keyCode = Int(event.keyCode)
        Runtime.shared.handleKey(down: false, code: keyCode)
    }
}
