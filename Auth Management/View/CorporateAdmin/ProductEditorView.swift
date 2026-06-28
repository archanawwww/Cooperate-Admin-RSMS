import SwiftUI

struct ProductEditorView: View {
    @State private var name: String = ""
    @State private var sku: String = ""
    @State private var description: String = ""
    @State private var selectedCategoryID: UUID? = nil
    
    // Authenticity
    @State private var isNFCEnabled: Bool = false
    @State private var requiresCertificate: Bool = false
    @State private var authNotes: String = ""
    
    let productToEdit: ProductMasterRecord?
    let categories: [Category]
    var onSave: (ProductMasterRecord) -> Void
    var onCancel: () -> Void
    
    // 2FA for action
    @State private var show2FA = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Product Name", text: $name)
                    TextField("SKU", text: $sku)
                    TextField("Description", text: $description)
                    
                    Picker("Category", selection: $selectedCategoryID) {
                        Text("None").tag(UUID?(nil))
                        ForEach(categories) { cat in
                            Text(cat.name).tag(UUID?(cat.id))
                        }
                    }
                }
                
                Section(header: Text("Authenticity Settings")) {
                    Toggle("NFC Enabled", isOn: $isNFCEnabled)
                    Toggle("Requires Certificate", isOn: $requiresCertificate)
                    TextField("Notes", text: $authNotes)
                }
            }
            .navigationTitle(productToEdit == nil ? "New Product" : "Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Trigger 2FA before saving
                        show2FA = true
                    }
                    .disabled(name.isEmpty || sku.isEmpty)
                }
            }
            .sheet(isPresented: $show2FA) {
                TwoFactorAuthView {
                    show2FA = false
                    saveProduct()
                }
            }
            .onAppear {
                if let p = productToEdit {
                    name = p.name
                    sku = p.sku
                    description = p.description ?? ""
                    selectedCategoryID = p.categoryID
                    isNFCEnabled = p.authenticitySettings.isNFCEnabled
                    requiresCertificate = p.authenticitySettings.requiresCertificate
                    authNotes = p.authenticitySettings.notes ?? ""
                }
            }
        }
    }
    
    private func saveProduct() {
        let authSettings = AuthenticitySettings(isNFCEnabled: isNFCEnabled, requiresCertificate: requiresCertificate, notes: authNotes.isEmpty ? nil : authNotes)
        
        let newProduct = ProductMasterRecord(
            id: productToEdit?.id ?? UUID(),
            name: name,
            description: description.isEmpty ? nil : description,
            categoryID: selectedCategoryID,
            sku: sku,
            authenticitySettings: authSettings,
            createdAt: productToEdit?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        onSave(newProduct)
    }
}
