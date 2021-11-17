//
//  ProfileViewController.swift
//  Sleep_Apnea
//
//  Created by Hamza Mian on 2021-02-04.
//

import UIKit

class ProfileViewController: UIViewController {
    @IBOutlet weak var nameText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //textfield attributes
        nameText.returnKeyType = .done
        nameText.autocapitalizationType = .words
        nameText.autocorrectionType = .no
        nameText.delegate = self
    }
    @IBAction func getName(_ sender: Any) {
        nameText.resignFirstResponder()
        if let text = nameText.text{
            username = text.uppercased() //update user text
            count = 0 //reset counter after user change.
            print("\(text)")
            //dismiss popover
            dismiss(animated: true, completion: nil) //any block to execute after this? Update completion
        }
    }
    
}
extension ProfileViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let text = textField.text{
            username = text.uppercased()
            print("\(text)")
            //dismiss popover
            dismiss(animated: true, completion: nil) //any block to execute after this? Update completion
        }
        return true
    }
}
