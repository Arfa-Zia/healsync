//
//  TextInputField.swift
//  HealSync
//
//  Created by Arfa on 12/01/2026.
//

import UIKit

class TextInputField: UITextField, UITextFieldDelegate{
    
    enum FieldType {
        case text
        case email
        case password
        case number
        case date
        case picker
    }
    private var fieldType: FieldType = .text
    private let padding = UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16)
    private var pickerData : [String] = []
    private var datePicker : UIDatePicker?
    private var onDateSelected: ((Date) -> Void)?
    var onValueChanged: ((String?) -> Void)?
    
    init(
        placeholder: String,
        type: FieldType ,
        color: UIColor = .white,
        alphaValue: CGFloat = 0.7,
        placeholderColor: UIColor = .secondaryLabel)
    {
        super.init(frame: .zero)
        configureField(placeholder: placeholder, placeholderColor: placeholderColor, type: type, color: color, alphaValue: alphaValue)
        self.delegate = self
        self.translatesAutoresizingMaskIntoConstraints = false
        self.fieldType = type
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc private func textDidChange() {
        clearError()
        onValueChanged?(text)
    }
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        switch fieldType {
        case .date, .picker:
            return false
        default:
            return true
        }
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        text = pickerData[row]

        clearError()
        onValueChanged?(text)
    }
    func showError() {
        layer.borderColor = UIColor.systemRed.cgColor
        layer.borderWidth = 1
    }
    func clearError() {
        layer.borderWidth = 0
    }
    private func configureField(
        placeholder: String,
        placeholderColor: UIColor,
        type: FieldType,
        color: UIColor,
        alphaValue: CGFloat
    ){
        self.backgroundColor = color.withAlphaComponent(alphaValue)
        self.layer.cornerRadius = 6
        self.font = .systemFont(ofSize: 16)
        self.textColor = .darkGray
        self.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: placeholderColor ]
        )
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        
        switch(type){
        case .date, .picker:
                tintColor = .clear
        default:
            break
        }
        
        configureFieldType(type)
    }
    
    private func configureFieldType(_ type: FieldType){
        switch type{
        case .text:
            keyboardType = .default
            autocapitalizationType = .words
        case .email:
            keyboardType = .emailAddress
            autocapitalizationType = .none
            autocorrectionType = .no
        case .password:
            isSecureTextEntry = true
            keyboardType = .default
        case .number:
            keyboardType = .numberPad
        case .date:
            setupDatePicker()
        case .picker:
            break
        }
    }
  
    private func setupDatePicker(){
        
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.maximumDate = Calendar.current.date(byAdding: .year, value: -18, to: Date())
        picker.minimumDate = Calendar.current.date(byAdding: .year, value: -100, to: Date())
        picker.preferredDatePickerStyle = .wheels
        picker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        
        if let date = Calendar.current.date(byAdding: .year, value: -25, to: Date()){
            picker.date = date
        }
      
        self.datePicker = picker
        self.inputView = picker
        
        setRightIcon(UIImage(systemName: "calendar"))
    }
    
    @objc func dateChanged(_ sender: UIDatePicker){
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.dateFormat = "dd MMM yyyy"
        self.text = formatter.string(from: sender.date)
        onDateSelected?(sender.date)
        
        clearError()
        onValueChanged?(text)
    }
   
    func setupPicker(data: [String]){
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        self.pickerData = data
        self.inputView = picker
        
        tintColor = .clear
    }
    
    func setRightIcon(_ image: UIImage?, tintColor: UIColor = .darkGray){
        guard let image = image else { return }
        
        let iconView = UIImageView(image: image)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = tintColor
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 24))
        iconView.frame = CGRect(x: 12, y: 2, width: 20, height: 20)
        paddingView.addSubview(iconView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(iconTapped))
        paddingView.addGestureRecognizer(tap)
        paddingView.isUserInteractionEnabled = true
        
        
        self.rightView = paddingView
        self.rightViewMode = .always
    }
    
    @objc func iconTapped(){
        self.becomeFirstResponder()
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    func setDateSelectionHandler(_ handler: @escaping (Date) -> Void){
        self.onDateSelected = handler
    }
    func getSelectedDate() -> Date? {
        return datePicker?.date
    }
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        if fieldType == .date || fieldType == .picker {
            return .zero
        }
        return super.caretRect(for: position)
    }
}

extension TextInputField: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
}
