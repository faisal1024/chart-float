import Cocoa
let size: CGFloat = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
let r = NSRect(x: 0, y: 0, width: size, height: size)
let bg = NSBezierPath(roundedRect: r.insetBy(dx: 60, dy: 60), xRadius: 220, yRadius: 220)
NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.16, alpha: 1).setFill(); bg.fill()
let line = NSBezierPath()
let pts: [(CGFloat, CGFloat)] = [(180,330),(330,520),(450,420),(620,700),(760,600),(860,760)]
line.move(to: NSPoint(x: pts[0].0, y: pts[0].1))
for p in pts.dropFirst() { line.line(to: NSPoint(x: p.0, y: p.1)) }
line.lineWidth = 56; line.lineCapStyle = .round; line.lineJoinStyle = .round
NSColor(calibratedRed: 0.20, green: 0.85, blue: 0.45, alpha: 1).setStroke(); line.stroke()
img.unlockFocus()
let tiff = img.tiffRepresentation!
let rep = NSBitmapImageRep(data: tiff)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "icon1024.png"))
