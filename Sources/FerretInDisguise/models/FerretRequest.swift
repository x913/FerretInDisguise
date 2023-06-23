public struct FerretRequest: Codable {
    let bundleId: String
    let osVersion: String
    let phoneModel: String
    let language: String
    let phoneTime: String
    let phoneTz: String
    let vpn: Bool
}
