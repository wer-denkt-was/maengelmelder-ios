//
//  OfflineSettingsViewController.swift
//  Maengelmelder
//
//  Created by Felix Leber on 22.04.25.
//

import UIKit
import JGProgressHUD

class OfflineSettingsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.title = "Offline-Daten"
    }

}

extension OfflineSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return MMSettings.shared.offlineMaps.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "offline_cell", for: indexPath) as! OfflineMapTableViewCell
        
        // Data sync is done automatically at the start
        if indexPath.section == 0 {
            cell.titleLabel.text = "Basisdaten"
            
            var subtitleText = "Um die App auch ohne Internetverbindung zu nutzen, müssen diese grundlegenden Offline-Daten heruntergeladen werden."
            if let dateString: String = UserDefaults.standard.string(forKey: "offlineDataLastUpdate") {
                subtitleText += "\nLetzte Aktualisierung: \(dateString)"
            }
            
            cell.subtitleLabel.text = subtitleText
            cell.iconView.tintColor = InternetUtility.shared.isOfflineDataAvailable() ? .green : MMColorScheme.shared.getColor(view: cell, type: .buttonBg)
            cell.iconView.image = InternetUtility.shared.isOfflineDataAvailable() ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "icloud.and.arrow.down")
            return cell
        }
        
        let map = MMSettings.shared.offlineMaps[indexPath.row]
        cell.titleLabel.text = map.name
        cell.subtitleLabel.text = String.init(format: "%d MB", map.size)
        cell.iconView.tintColor = map.isDownloaded ? .green : MMColorScheme.shared.getColor(view: cell, type: .buttonBg)
        cell.iconView.image = map.isDownloaded ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "icloud.and.arrow.down")
        
        let latestMapVersion = UserDefaults.standard.integer(forKey: "mapManager.offlineMapVersion");
        let isOutdated = MapManager.isMapFileOutdated(map: map, currentVersion: latestMapVersion)
        if isOutdated {
            cell.iconView.image = UIImage(systemName: "exclamationmark.triangle.fill")
            cell.iconView.tintColor = .yellow
        }
        
        if map.size == 0 {
            map.fetchFileSize {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Daten" : "Karten"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            let alert = UIAlertController(title: "Daten \(InternetUtility.shared.isOfflineDataAvailable() ? "aktualisieren" : "herunterladen")", message: "Sollen die grundlegenden Offline-Daten \(InternetUtility.shared.isOfflineDataAvailable() ? "aktualisiert" : "heruntergeladen") werden?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ja", style: .default, handler: { _ in
                let hud = JGProgressHUD(style: .dark)
                hud.textLabel.text = "Lade Daten..."
                hud.show(in: self.view)
                InternetUtility.shared.loadOfflineData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                    if InternetUtility.shared.isOfflineDataAvailable() {
                        hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                        hud.textLabel.text = "Daten erfolgreich heruntergeladen!"
                    } else {
                        hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        hud.textLabel.text = "Daten konnten nicht heruntergeladen werden!"
                    }
                    hud.dismiss(afterDelay: 3, animated: true)
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                })
            }))
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
            self.present(alert, animated: true)
        } else {
            let map = MMSettings.shared.offlineMaps[indexPath.row]
            
            let alertTitle = "Karte \(map.name)"
            var alertMessage = ""
            if !map.isDownloaded {
                alertMessage = "Soll die Karte heruntergeladen werden?"
            }
            let alert = UIAlertController(
                title: alertTitle,
                message: alertMessage,
                preferredStyle: .alert
            )
            let hud = JGProgressHUD(style: .dark)
            let latestMapVersion = UserDefaults.standard.integer(forKey: "mapManager.offlineMapVersion");
            
            if map.isDownloaded {
                // Delete
                alert.addAction(UIAlertAction(title: "Karte entfernen", style: .default, handler: { _ in
                    map.deleteLocalFile()
                    hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                    hud.textLabel.text = "Karte erfolgreich gelöscht!"
                    hud.show(in: self.view)
                    hud.dismiss(afterDelay: 3, animated: true)
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }))
                
                if (MapManager.isMapFileOutdated(map: map, currentVersion: latestMapVersion)) {
                    // Update
                    alert.addAction(UIAlertAction(title: "Karte aktualisieren", style: .default, handler: { _ in
                        map.deleteLocalFile()
                        hud.indicatorView = JGProgressHUDPieIndicatorView()
                        hud.textLabel.text = "Karte wird aktualisiert..."
                        hud.show(in: self.view)
                        UIApplication.shared.isIdleTimerDisabled = true
                        map.download { progress in
                            hud.progress = Float(progress)
                            hud.detailTextLabel.text = String(format: "%d%%", Int(progress * 100))
                        } completion: { success in
                            UIApplication.shared.isIdleTimerDisabled = false
                            if success {
                                hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                                hud.textLabel.text = "Karte erfolgreich aktualisiert!"
                            } else {
                                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                                hud.textLabel.text = "Karte konnte nicht aktualisiert werden!"
                            }
                            hud.dismiss(afterDelay: 3, animated: true)

                            // Update map version to the latest
                            MapManager.setMapFileUpdated(map: map, currentVersion: latestMapVersion)
                            tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    }))
                }
            } else {
                // Download
                alert.addAction(UIAlertAction(title: "Ja", style: .default, handler: { _ in
                    hud.textLabel.text = "Karte wird heruntergeladen..."
                    hud.indicatorView = JGProgressHUDPieIndicatorView()
                    hud.show(in: self.view)
                    UIApplication.shared.isIdleTimerDisabled = true
                    map.download { progress in
                        hud.progress = Float(progress)
                        hud.detailTextLabel.text = String(format: "%d%%", Int(progress * 100))
                    } completion: { success in
                        UIApplication.shared.isIdleTimerDisabled = false
                        if success {
                            hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                            hud.textLabel.text = "Karte erfolgreich heruntergeladen!"
                        } else {
                            hud.indicatorView = JGProgressHUDErrorIndicatorView()
                            hud.textLabel.text = "Karte konnte nicht heruntergeladen werden!"
                        }
                        hud.dismiss(afterDelay: 3, animated: true)
                        
                        // Update map version to the latest
                        MapManager.setMapFileUpdated(map: map, currentVersion: latestMapVersion)
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                }))
            }
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
            self.present(alert, animated: true)
        }
    }
}
