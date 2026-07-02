import Foundation
import Combine

extension AuthenticationManager {
    
    public func addCompanyPolicy(title: String, content: String) {
        let newPolicy = CompanyPolicy(title: title, content: content)
        companyPolicies.append(newPolicy)
        Task {
            do {
                try await SupabaseAuthService.shared.createCompanyPolicy(
                    SupabaseCompanyPolicy(id: newPolicy.id, title: newPolicy.title, content: newPolicy.content, lastUpdated: newPolicy.lastUpdated)
                )
            } catch {
                print("Failed to create company policy: \(error)")
            }
        }
    }
    
    public func updateCompanyPolicy(_ policy: CompanyPolicy) {
        if let index = companyPolicies.firstIndex(where: { $0.id == policy.id }) {
            var updatedPolicy = policy
            updatedPolicy.lastUpdated = Date()
            companyPolicies[index] = updatedPolicy
            Task {
                do {
                    try await SupabaseAuthService.shared.updateCompanyPolicy(
                        SupabaseCompanyPolicy(id: updatedPolicy.id, title: updatedPolicy.title, content: updatedPolicy.content, lastUpdated: updatedPolicy.lastUpdated)
                    )
                } catch {
                    print("Failed to update company policy: \(error)")
                }
            }
        }
    }
    
    public func deleteCompanyPolicy(id: UUID) {
        companyPolicies.removeAll { $0.id == id }
        Task {
            do {
                try await SupabaseAuthService.shared.deleteCompanyPolicy(id: id)
            } catch {
                print("Failed to delete company policy: \(error)")
            }
        }
    }
}
