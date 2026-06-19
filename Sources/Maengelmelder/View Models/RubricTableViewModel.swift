//
//  RubricTableViewModel.swift
//  MM
//
//  Created by Felix on 01.08.23.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit

class RubricTableViewModel : NSObject, UITableViewDelegate, UITableViewDataSource {
    
    private var rubrics = Array<String>()
    private let viewModel : ReportTypeViewModel
    private let containerView : UIView
    private let rubricInfoLabel : UILabel
    
    init(viewModel: ReportTypeViewModel, containerView: UIView, rubricInfoLabel: UILabel) {
        self.viewModel = viewModel
        self.rubrics = self.viewModel.getRubrics(domainid: self.viewModel.getSelectedDomainID())
        self.containerView = containerView
        self.rubricInfoLabel = rubricInfoLabel
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rubrics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = rubrics[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.containerView.isHidden = true
        self.viewModel.selectRubric(self.rubrics[indexPath.row])
        self.rubricInfoLabel.text = String.init(format: "Rubrik: %@", self.rubrics[indexPath.row])
    }
    
}
