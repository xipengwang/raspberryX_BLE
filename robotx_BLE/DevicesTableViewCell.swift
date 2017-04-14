//
//  DevicesTableViewCell.swift
//  robotx_BLE
//
//  Created by Xipeng Wang on 4/14/17.
//  Copyright © 2017 Xipeng Wang. All rights reserved.
//

import UIKit

class DevicesTableViewCell: UITableViewCell {

    @IBOutlet weak var bleDeviceName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
