import Foundation

class ShortcutStorage {
    static let shared = ShortcutStorage()
    
    private let userDefaults = UserDefaults.standard
    private let mappingsKey = "shortcutMappings"
    
    private init() {
        // Initialisation privée pour assurer le singleton
    }
    
    func saveMappings(_ mappings: [ShortcutMapping]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(mappings)
            userDefaults.set(data, forKey: mappingsKey)
            userDefaults.synchronize() // Force la sauvegarde immédiate
            print("Mappings sauvegardés: \(mappings.count) éléments")
        } catch {
            print("Erreur lors de l'encodage des mappings: \(error)")
        }
    }
    
    func loadMappings() -> [ShortcutMapping] {
        guard let data = userDefaults.data(forKey: mappingsKey) else {
            print("Aucun mapping trouvé dans UserDefaults")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let mappings = try decoder.decode([ShortcutMapping].self, from: data)
            print("Mappings chargés: \(mappings.count) éléments")
            return mappings
        } catch {
            print("Erreur lors du décodage des mappings: \(error)")
            // En cas d'erreur, retourner un tableau vide pour éviter de planter
            return []
        }
    }
    
    // Méthode pour effacer tous les mappings (utile pour le débogage)
    func clearAllMappings() {
        userDefaults.removeObject(forKey: mappingsKey)
        userDefaults.synchronize()
        print("Tous les mappings ont été effacés")
    }
}
