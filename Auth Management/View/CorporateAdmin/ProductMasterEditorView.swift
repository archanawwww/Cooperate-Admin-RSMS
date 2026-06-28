import SwiftUI

struct ProductMasterEditorView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    let product: ProductMasterRecord?
    var onSave: (ProductMasterRecord) -> Void

    // Form inputs state variables
    @State private var name: String
    @State private var sku: String
    @State private var categoryID: UUID?
    @State private var brand: String
    @State private var priceString: String
    @State private var costPriceString: String
    @State private var taxString: String
    @State private var barcode: String
    @State private var description: String
    @State private var isActive: Bool
    
    @State private var statusMessage: String?
    @State private var isSuccess = false

    init(product: ProductMasterRecord? = nil, onSave: @escaping (ProductMasterRecord) -> Void) {
        self.product = product
        self.onSave = onSave
        
        _name = State(initialValue: product?.name ?? "")
        _sku = State(initialValue: product?.sku ?? "")
        _categoryID = State(initialValue: product?.categoryID)
        _brand = State(initialValue: product?.brand ?? "")
        _priceString = State(initialValue: product != nil ? String(format: "%.0f", product!.price) : "")
        _costPriceString = State(initialValue: product != nil ? String(format: "%.0f", product!.costPrice) : "")
        _taxString = State(initialValue: product != nil ? String(format: "%.0f", product!.tax) : "18")
        _barcode = State(initialValue: product?.barcode ?? "")
        _description = State(initialValue: product?.description ?? "")
        _isActive = State(initialValue: product?.isActive ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Core Identity") {
                    TextField("Product Name", text: $name)
                        .autocorrectionDisabled()
                    
                    TextField("SKU Code", text: $sku)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    
                    TextField("Brand", text: $brand)
                        .autocorrectionDisabled()
                    
                    Picker("Category", selection: $categoryID) {
                        Text("None").tag(UUID?.none)
                        ForEach(authManager.itemCategories) { cat in
                            Text(cat.name).tag(UUID?.some(cat.id))
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Financials & Pricing") {
                    HStack {
                        Text("Retail Price")
                        Spacer()
                        TextField("₹ Price", text: $priceString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Cost Price")
                        Spacer()
                        TextField("₹ Cost", text: $costPriceString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Tax Rate (%)")
                        Spacer()
                        TextField("Tax", text: $taxString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("System Details") {
                    TextField("Barcode (EAN-13)", text: $barcode)
                        .keyboardType(.numberPad)
                    
                    Toggle("Is Active (Sellable)", isOn: $isActive)
                        .tint(MatteTheme.Colors.primaryGold)
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text("Enter premium description...")
                                        .foregroundColor(Color(uiColor: .placeholderText))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundColor(isSuccess ? MatteTheme.Colors.success : MatteTheme.Colors.error)
                    }
                }
            }
            .navigationTitle(product == nil ? "New Product Master" : "Edit Product Master")
            .navigationBarTitleDisplayMode(.inline)
            .tint(MatteTheme.Colors.primaryGold)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MatteTheme.Colors.espresso)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundColor(MatteTheme.Colors.primaryGold)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSku = sku.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanName.isEmpty else {
            statusMessage = "Product Name cannot be empty."
            isSuccess = false
            return
        }
        
        guard !cleanSku.isEmpty else {
            statusMessage = "SKU Code cannot be empty."
            isSuccess = false
            return
        }
        
        guard !cleanBrand.isEmpty else {
            statusMessage = "Brand cannot be empty."
            isSuccess = false
            return
        }

        let price = Double(priceString.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
        let costPrice = Double(costPriceString.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
        let tax = Double(taxString.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 18.0

        let savedRecord = ProductMasterRecord(
            id: product?.id ?? UUID(),
            name: cleanName,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            categoryID: categoryID,
            sku: cleanSku,
            authenticitySettings: product?.authenticitySettings ?? AuthenticitySettings(isNFCEnabled: true, requiresCertificate: false),
            createdAt: product?.createdAt ?? Date(),
            updatedAt: Date(),
            brand: cleanBrand,
            price: price,
            costPrice: costPrice,
            tax: tax,
            barcode: barcode.trimmingCharacters(in: .whitespacesAndNewlines),
            isActive: isActive,
            isArchived: product?.isArchived ?? false
        )

        onSave(savedRecord)
        isSuccess = true
        statusMessage = "Product Master saved."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}
