//
//  MessagesViewController.swift
//  SpamDetector MessagesExtension
//
//  Created by Nikhil Raghavendra on 5/5/18.
//  Copyright © 2018 Nikhil Raghavendra. All rights reserved.
//

import UIKit
import Messages
import CoreML

class MessagesViewController: MSMessagesAppViewController {
    
    // MARK: Properties
    @IBOutlet weak var predictedLabel: UILabel!
    
    // MARK: Actions
    @IBAction func detectSpam(_ sender: UIButton) {
        // Get the copied message from clipboard
        let copied = UIPasteboard.general.string
        if let copiedText = copied {
            // Convert the text to a TF-IDF vector
            let vector = tfidf(sms: copiedText)
            // Predict the class
            do {
                // Try to make a prediction using the CoreML model.
                let prediction = try MessageClassifier().prediction(message: vector).label
                predictedLabel.text = prediction
            } catch {
                // If therer is an error in making the prediction,
                predictedLabel.text = "An error occurred..."
            }
        }
    }
    
    // MARK: Methods
    func tfidf(sms: String) -> MLMultiArray {
        // Returns the full pathname for the resource identified by the specified name and file
        // extension. We need both of these files to carry out the TF-IDF vectorization.
        let wordsFile = Bundle.main.path(forResource: "words_ordered", ofType: "txt")
        let smsFile = Bundle.main.path(forResource: "SMSSpamCollection", ofType: "txt")
        do {
            // Get the raw text data from both of these files in the UTF-8 format
            let wordsTextFile = try String(contentsOfFile: wordsFile!, encoding: String.Encoding.utf8)
            let smsTextFile = try String(contentsOfFile: smsFile!, encoding: String.Encoding.utf8)
            // Get the text data that is separated by new lines for each row
            var wordsData = wordsTextFile.components(separatedBy: .newlines)
            var smsData = smsTextFile.components(separatedBy: .newlines)
            // Remove trailing new lines
            wordsData.removeLast()
            smsData.removeLast()
            // Split the sms word by word and get an array of words
            let wordsInMessage = sms.split(separator: " ")
            // Vectorize the words
            let vectorized = try MLMultiArray(shape: [NSNumber(integerLiteral: wordsData.count)], dataType: MLMultiArrayDataType.double)
            // Iterate over each word in words_ordered.txt file
            for i in 0 ..< wordsData.count {
                // Get the current word given iteration
                let word = wordsData[i]
                // Check if the sms cointains the word that we are looking at in the words_ordered.txt
                // file. If it does, increase the word count by one.
                if sms.contains(word) {
                    // Initialize the word count to 0 for every instance the word is present in the sms
                    var wordCount = 0
                    // substr is an individual word that is found in the copied message that was passed
                    // to this function.
                    for substr in wordsInMessage {
                        // If the word in the copied message equals the current word we are iterating
                        // over in the words_ordered text corpus, increment the word count by one.
                        if substr.elementsEqual(word) {
                            wordCount += 1
                        }
                    }
                    // Term frequency (TF in TF-IDF)
                    let tf = Double(wordCount) / Double(wordsInMessage.count)
                    // Document count for calculating the Inverse Document Frequency (IDF in TF-IDF)
                    var docCount = 0
                    // Iterate over each sms in the SMSSpamCollection
                    for msg in smsData {
                        // If the message contains the word we are looking at in the words_ordered.txt
                        // file, increase the document count by one.
                        if msg.contains(word) {
                            docCount += 1
                        }
                    }
                    // Calculate the Inverse Document Frequency (IDF in TF-IDF)
                    let idf = log(Double(smsData.count) / Double(docCount))
                    // TF-IDF
                    vectorized[i] = NSNumber(value: tf * idf)
                } else {
                    // If the word is not present in the copied message, set the value to 0.0
                    vectorized[i] = 0.0
                }
            }
            // Return the vectorized data
            return vectorized
        } catch {
            // If there was an error, return an empty MLMultiArray
            return MLMultiArray()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Conversation Handling
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }
}
