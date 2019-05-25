//
//  ResultCell.swift
//  parkit
//
//  Created by Arthur Péligry on 25/05/2019.
//  Copyright © 2019 Arthur Péligry. All rights reserved.
//

import UIKit

class ResultCell: UITableViewCell {

    @IBOutlet weak var searchResultAddress: UILabel!
    
    @IBOutlet weak var searchResultAddress2: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
