//
//  pokemonCell.swift
//  PogoTool
//
//  Created by Tchang on 04/08/16.
//  Copyright © 2016 Tchang. All rights reserved.
//

import UIKit

class pokemonCell: UITableViewCell {

    
    @IBOutlet weak var pokemonImage: UIImageView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var statText: UITextField!
    @IBOutlet weak var transferButton: UIButton!
    @IBOutlet weak var evolveButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.clearColor()
        self.userInteractionEnabled = false
        
        nameText.enabled = false
        statText.enabled = false
        nameText.backgroundColor = UIColor.clearColor()
        statText.backgroundColor = UIColor.clearColor()
        nameText.borderStyle = UITextBorderStyle.None
        statText.borderStyle = UITextBorderStyle.None
        
        pokemonImage.image = UIImage()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
