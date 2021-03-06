//
//  ChatViewController.swift
//  WebSockets
//
//  Created by Elina Batyrova on 08.10.2020.
//

import UIKit

class ChatViewController: UIViewController {
    
    //MARK: - Nested Types
    
    private enum Identifiers {
        static let messageTableCell = "MessageTableCell"
    }
    
    //MARK: - Instance Properties
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var messageTextField: UITextField!
    @IBOutlet private weak var bottomViewHeightConstraint: NSLayoutConstraint!
    
    //MARK: - Properties
    
    private var username: String!
    
    private var socketManager = Managers.socketManager
    
    private var messages: [MessageData] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupKeyboardNotifications()
        
        self.navigationItem.title = username
        self.messageTextField.delegate = self
        
        startObservingMessages()
        startObservingTypingUpdate()
    }
    
    //MARK: - Instance Methods
    
    func apply(username: String) {
        self.username = username
    }
    
    //MARK: - Button actions
    
    @IBAction private func onSendButtonTouchUpInside(_ sender: Any) {
        let text = messageTextField.text ?? ""
        
        socketManager.send(message: text, username: self.username)
        messageTextField.text = ""
        messageTextField.resignFirstResponder()
    }
    
    //MARK: - Observing methods
    
    func startObservingMessages() {
        socketManager.observeMessages(completionHandler: { [weak self] data in
            let name = data["nickname"] as! String
            let text = data["message"] as! String
            
            let message = MessageData(text: text, sender: name)
            
            self?.messages.append(message)
        })
    }
    
    func startObservingTypingUpdate() {
        socketManager.observeUserTypingUpdate(completionHandler: { [weak self] data in
            
            let typingUsersArray = data.keys.sorted()
            if !typingUsersArray.isEmpty {
                let typingUsersString = typingUsersArray.joined(separator:", ")
                let informationString = "\(typingUsersString) typing..."
                self?.navigationItem.title = informationString
            } else {
                self?.navigationItem.title = self?.username
            }
        })
    }
    
    //MARK: - Keyboard setup
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillShow(with:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillHide(with:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc
    private func keyboardWillShow(with notification: Notification) {
        guard let info = notification.userInfo, let keyboardEndSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size else {
            return
        }
        
        let keyboardHeight = keyboardEndSize.height
        
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.bottomViewHeightConstraint.constant = keyboardHeight
            
            self?.view.layoutIfNeeded()
        }
    }
    
    @objc
    private func keyboardWillHide(with notification: Notification) {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.bottomViewHeightConstraint.constant = 0
            
            self?.view.layoutIfNeeded()
        }
    }
}

//MARK: - UITextFieldDelegate

extension ChatViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        socketManager.startType(with: self.username)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        socketManager.stopType(with: self.username)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        messageTextField.text = ""
        return messageTextField.resignFirstResponder()
    }
}

//MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.messageTableCell, for: indexPath) as! MessageTableViewCell
        
        cell.configure(message: message.text, username: message.sender)
        
        return cell
    }
}
