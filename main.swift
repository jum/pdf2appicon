//
//  main.swift
//  pdf2appicon
//
//  Created by Jens-Uwe Mager on 03.10.17.
//  Copyright © 2017 Best Search Infobrokerage, Inc. All rights reserved.
//

import Commander
import AppKit

struct Image: Codable {
	var size: String
	var idiom: String
	var filename: String
	var scale: String
}

struct Info: Codable {
	var version: Int
	var author: String
}

struct Contents: Codable {
	var images: [Image]
	var info: Info
}

let contents = Contents(images: [
	Image(size: "20x20", idiom: "iphone", filename: "NotificationIcon@2x.png", scale: "2x"),
	Image(size: "20x20", idiom: "iphone", filename: "NotificationIcon@3x.png", scale: "3x"),
	Image(size: "29x29", idiom: "iphone", filename: "Icon-Small.png", scale: "1x"),
	Image(size: "29x29", idiom: "iphone", filename: "Icon-Small@2x.png", scale: "2x"),
	Image(size: "29x29", idiom: "iphone", filename: "Icon-Small@3x.png", scale: "3x"),
	Image(size: "40x40", idiom: "iphone", filename: "Icon-40@2x.png", scale: "2x"),
	Image(size: "40x40", idiom: "iphone", filename: "Icon-40@3x.png", scale: "3x"),
	Image(size: "57x57", idiom: "iphone", filename: "Icon.png", scale: "1x"),
	Image(size: "57x57", idiom: "iphone", filename: "Icon@2x.png", scale: "2x"),
	Image(size: "60x60", idiom: "iphone", filename: "Icon-60@2x.png", scale: "2x"),
	Image(size: "60x60", idiom: "iphone", filename: "Icon-60@3x.png", scale: "3x"),
	Image(size: "20x20", idiom: "ipad", filename: "NotificationIcon~ipad.png", scale: "1x"),
	Image(size: "20x20", idiom: "ipad", filename: "NotificationIcon~ipad@2x.png", scale: "2x"),
	Image(size: "29x29", idiom: "ipad", filename: "Icon-Small.png", scale: "1x"),
	Image(size: "29x29", idiom: "ipad", filename: "Icon-Small@2x.png", scale: "2x"),
	Image(size: "40x40", idiom: "ipad", filename: "Icon-40.png", scale: "1x"),
	Image(size: "40x40", idiom: "ipad", filename: "Icon-40@2x.png", scale: "2x"),
	Image(size: "50x50", idiom: "ipad", filename: "Icon-Small-50.png", scale: "1x"),
	Image(size: "50x50", idiom: "ipad", filename: "Icon-Small-50@2x.png", scale: "2x"),
	Image(size: "72x72", idiom: "ipad", filename: "Icon-72.png", scale: "1x"),
	Image(size: "72x72", idiom: "ipad", filename: "Icon-72@2x.png", scale: "2x"),
	Image(size: "76x76", idiom: "ipad", filename: "Icon-76.png", scale: "1x"),
	Image(size: "76x76", idiom: "ipad", filename: "Icon-76@2x.png", scale: "2x"),
	Image(size: "83.5x83.5", idiom: "ipad", filename: "Icon-83.5@2x.png", scale: "2x"),
	Image(size: "1024x1024", idiom: "ios-marketing", filename: "iTunesArtwork.png", scale: "1x"),
], info: Info(version: 1, author: "pdf2appicon"))

command(
	Option("page", default: 1, description: "page to render"),
	Flag("preserveaspectratio", default: true, description: "preserve the aspect ratio in the output"),
	Argument<String>("pdfin", description: "The PDF input file"),
	Argument<String>("outdir", description: "Destination dir")
) { (pageno, preserveaspectratio, pdfin, outdir) throws  in
	let url = URL(fileURLWithPath: pdfin)
	if let pdfdoc = CGPDFDocument(url as CFURL) {
		if let page = pdfdoc.page(at: pageno) {
			let fm = FileManager.default
			let destDirUrl = URL(fileURLWithPath: "\(outdir)/AppIcon.appiconset")
			try fm.createDirectory(at: destDirUrl, withIntermediateDirectories: true)
			for imFmt in contents.images {
				let wh = imFmt.size.split(separator: "x")
				var width: Double = 0
				var height: Double = 0
				var scale: Double = 1
				Scanner(string: String(wh[0])).scanDouble(&width)
				Scanner(string: String(wh[1])).scanDouble(&height)
				Scanner(string: String(imFmt.scale)).scanDouble(&scale)
				let size = CGSize(width: width*scale, height: height*scale)
				let smallPageRect = page.getBoxRect(.cropBox)
				//let cspace = NSColorSpaceName.deviceRGB
				let cspace = NSDeviceRGBColorSpace
				let image = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: cspace, bytesPerRow: 0, bitsPerPixel: 0)!
				let destRect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
				let pdfScale = size.width/smallPageRect.size.width
				var drawingTransform = page.getDrawingTransform(.cropBox, rect: destRect, rotate: 0, preserveAspectRatio: preserveaspectratio)
				if pdfScale > 1 {
					drawingTransform = drawingTransform.scaledBy(x: pdfScale, y: pdfScale)
					drawingTransform.tx = 0
					drawingTransform.ty = 0
				}
				let ctx = NSGraphicsContext(bitmapImageRep: image)!
				let cgctx = ctx.cgContext
				cgctx.concatenate(drawingTransform)
				cgctx.drawPDFPage(page)
				if let data = image.representation(using: NSPNGFileType, properties: [:]) {
					let outurl = URL(fileURLWithPath: "\(outdir)/AppIcon.appiconset/\(imFmt.filename)")
					try data.write(to: outurl)
				} else {
					throw ArgumentParserError("Unable to create PNG representation")
				}
			}
			let enc = JSONEncoder()
			enc.outputFormatting = .prettyPrinted
			let data = try enc.encode(contents)
			//let data = try JSONSerialization.data(withJSONObject: Images, options: [.prettyPrinted])
			let outurl = URL(fileURLWithPath: "\(outdir)/AppIcon.appiconset/Contents.json")
			try data.write(to: outurl)
		} else {
			throw ArgumentParserError("could not find page \(pageno) in \(url.absoluteString)")
		}
	} else {
		throw ArgumentParserError("Unable to open \(url.absoluteString)")
	}
}.run()
