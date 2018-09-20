import UIKit

open class CodeInputView: UIView, UIKeyInput {
    open var delegate: CodeInputViewDelegate?
    private var nextTag = 1
    
    // MARK: - UIResponder
    
    open override var canBecomeFirstResponder : Bool {
        return true
    }
    
    // MARK: - UIView
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        // calculate dims
        let spaceV = CGFloat(10)
        let spaceH = CGFloat(15)
        let height = frame.size.height - spaceV * 2
        let width = ((frame.size.width - spaceH) / 6) - spaceH
        
        
        // Add six digitLabels
        var lframe = CGRect(x: spaceH, y: spaceV, width: width, height: height)
        for index in 1...6 {
            let digitLabel = UILabel(frame: lframe)
            digitLabel.font = .systemFont(ofSize: 42)
            digitLabel.tag = index
            digitLabel.text = "–"
            digitLabel.textAlignment = .center
            addSubview(digitLabel)
            lframe.origin.x += width + spaceH
        }
    }
    
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") } // NSCoding
    
    // MARK: - UIKeyInput
    
    public var hasText : Bool {
        return nextTag > 1 ? true : false
    }
    
    open func insertText(_ text: String) {
        if nextTag < 7 {
            (viewWithTag(nextTag)! as! UILabel).text = text
            nextTag += 1
            
            if nextTag == 7 {
                var code = ""
                for index in 1..<nextTag {
                    code += (viewWithTag(index)! as! UILabel).text!
                }
                delegate?.codeInputView(self, didFinishWithCode: code)
            }
        }
    }
    
    open func deleteBackward() {
        if nextTag > 1 {
            nextTag -= 1
            (viewWithTag(nextTag)! as! UILabel).text = "–"
        }
    }
    
    open func clear() {
        while nextTag > 1 {
            deleteBackward()
        }
    }
    
    // MARK: - UITextInputTraits
    
    open var keyboardType: UIKeyboardType { get { return .numberPad } set { } }
}

public protocol CodeInputViewDelegate {
    func codeInputView(_ codeInputView: CodeInputView, didFinishWithCode code: String)
}
