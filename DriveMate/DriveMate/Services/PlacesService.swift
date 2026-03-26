import Foundation

struct PlaceResult: Identifiable {
    let id: String
    let displayName: String
    let formattedAddress: String?
    let rating: Double?
}

struct PlacePhone {
    let nationalPhone: String?
    let internationalPhone: String?
}

actor PlacesService {
    private let session: URLSession
    private let baseURL = "https://places.googleapis.com/v1/"

    init(session: URLSession = .shared) {
        self.session = session
    }

    enum PlacesError: LocalizedError {
        case noAPIKey
        case httpError(Int)
        case noResults
        case networkError(Error)
        case decodingError

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "No se ha configurado la API Key de Google Places."
            case .httpError(let code): return "Error HTTP Places: \(code)"
            case .noResults: return "No se encontraron lugares."
            case .networkError(let error): return "Error de red: \(error.localizedDescription)"
            case .decodingError: return "Error al procesar resultados de Places."
            }
        }
    }

    func searchPlaces(query: String, apiKey: String) async throws -> [PlaceResult] {
        guard !apiKey.isEmpty else { throw PlacesError.noAPIKey }

        let url = URL(string: "\(baseURL)places:searchText")!

        let body: [String: Any] = [
            "textQuery": query,
            "maxResultCount": 3
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(
            "places.displayName,places.formattedAddress,places.rating,places.id",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw PlacesError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlacesError.decodingError
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw PlacesError.httpError(httpResponse.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let places = json["places"] as? [[String: Any]], !places.isEmpty else {
            throw PlacesError.noResults
        }

        return places.compactMap { place in
            guard let id = place["id"] as? String,
                  let displayNameObj = place["displayName"] as? [String: Any],
                  let name = displayNameObj["text"] as? String else { return nil }

            return PlaceResult(
                id: id,
                displayName: name,
                formattedAddress: place["formattedAddress"] as? String,
                rating: place["rating"] as? Double
            )
        }
    }

    func getPhoneNumber(placeId: String, apiKey: String) async throws -> PlacePhone {
        guard !apiKey.isEmpty else { throw PlacesError.noAPIKey }

        let url = URL(string: "\(baseURL)places/\(placeId)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(
            "nationalPhoneNumber,internationalPhoneNumber",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )
        request.timeoutInterval = 10

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw PlacesError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PlacesError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PlacesError.decodingError
        }

        return PlacePhone(
            nationalPhone: json["nationalPhoneNumber"] as? String,
            internationalPhone: json["internationalPhoneNumber"] as? String
        )
    }
}
