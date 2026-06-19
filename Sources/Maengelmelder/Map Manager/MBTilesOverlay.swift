//
//  MBTilesOverlay.swift
//  Maengelmelder
//
//  Created by Felix Leber on 16.04.25.
//

import MapKit
import SQLite

class MBTilesOverlay: MKTileOverlay {
    
    private let tiles = Table("tiles")
    private let zoomLevel = SQLite.Expression<Int>("zoom_level")
    private let tileColumn = SQLite.Expression<Int>("tile_column")
    private let tileRow = SQLite.Expression<Int>("tile_row")
    private let tileData = SQLite.Expression<Blob>("tile_data")
    
    private let db : Connection?
    
    init (filePath: String) {
        db = try? Connection(filePath)
        
        super.init(urlTemplate: nil)
    }
    
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, (any Error)?) -> Void) {
        result(getTileFor(zoomLevel: path.z, column: path.x, row: path.y), nil)        
    }
    
    private func getTileFor(zoomLevel: Int, column: Int, row: Int) -> Data? {
        guard let db = db else {
            return nil
        }
        
        let col = Int(pow(2.0, Double(zoomLevel))) - row - 1
        
        do {
            let query = tiles.where(zoomLevel == self.zoomLevel).where(column == self.tileColumn).where(col == self.tileRow)
            for tile in try db.prepare(query) {
                return Data(tile[self.tileData].bytes)
            }
        } catch let error {
            print(error)
        }
        return nil
    }


}
