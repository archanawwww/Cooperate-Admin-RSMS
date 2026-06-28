import Foundation
import Combine

extension AuthenticationManager {
    
    private var companyPoliciesKey: String { "auth-management.company-policies" }
    
    public var companyPolicies: [CompanyPolicy] {
        get {
            guard let data = UserDefaults.standard.data(forKey: companyPoliciesKey),
                  let decoded = try? JSONDecoder().decode([CompanyPolicy].self, from: data) else {
                return defaultPolicies
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: companyPoliciesKey)
            }
        }
    }
    
    private var defaultPolicies: [CompanyPolicy] {
        [
            CompanyPolicy(
                title: "Return & Exchange Policy",
                content: "Items in pristine condition can be returned within 14 days of purchase. Excludes customized leather items and high-end watches, which require a boutique manager inspection.",
                lastUpdated: Date()
            ),
            CompanyPolicy(
                title: "Employee Discount Rules",
                content: "Active boutique staff members receive a 30% discount on leather apparel and 15% on timepieces. Items must be purchased for personal use or direct family members only.",
                lastUpdated: Date()
            ),
            CompanyPolicy(
                title: "High-Value Transfer Verification",
                content: "Double audit authorization (from both dispatching and receiving boutique managers) is strictly required for stock transfers exceeding ₹5,00,000 in retail value.",
                lastUpdated: Date()
            )
        ]
    }
    
    public func addCompanyPolicy(title: String, content: String) {
        var policies = companyPolicies
        let newPolicy = CompanyPolicy(title: title, content: content)
        policies.append(newPolicy)
        companyPolicies = policies
        objectWillChange.send()
    }
    
    public func updateCompanyPolicy(_ policy: CompanyPolicy) {
        var policies = companyPolicies
        if let index = policies.firstIndex(where: { $0.id == policy.id }) {
            var updatedPolicy = policy
            updatedPolicy.lastUpdated = Date()
            policies[index] = updatedPolicy
            companyPolicies = policies
            objectWillChange.send()
        }
    }
    
    public func deleteCompanyPolicy(id: UUID) {
        var policies = companyPolicies
        policies.removeAll(where: { $0.id == id })
        companyPolicies = policies
        objectWillChange.send()
    }
}
