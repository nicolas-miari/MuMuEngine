How spritesheets are stored in the editor document

Library/
   Spritesheets/
       AAAA/
           Metadata.plist
           Sources/
               0001.png
               0002.png
               ...

class LibraryAsset

class Editor.Spritesheet: LibraryAsset {

    //
    var scaleFactorOfSources: CGFloat

    // Size in points of the exported image. Subimages can be 
    // arranged freely within this rectangle.
    var canvazSize: CGSize

    // dictionary of named images available for arranging
    var sources: [String: CGImage]
    
    // The current lcoation of each subimage.
    var subregions: [String: CGRect] 
}

class Editor.Tileset: LibraryAsset
