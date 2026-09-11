import Flutter
import FoundationModels

/// Bridges Apple's on-device Foundation Models framework to Dart via the
/// Pigeon-generated `FoundationModelHostApi` (see
/// pigeons/foundation_model.dart — re-run `dart run pigeon` after editing
/// that schema, don't hand-edit FoundationModelApi.g.swift).
///
/// Personal-tool scope: single session at a time, no persistence across
/// app relaunches. The FoundationModels framework itself requires iOS 26+
/// on an Apple Intelligence-eligible device (iPhone 15 Pro or later) with
/// Apple Intelligence enabled — `checkAvailability` lets the Dart side gate
/// any AI-powered UI before calling the other two methods.
@available(iOS 26.0, *)
class FoundationModelHandler: NSObject, FoundationModelHostApi {
    private var session: LanguageModelSession?

    static func register(with registrar: FlutterPluginRegistrar) {
        let handler = FoundationModelHandler()
        FoundationModelHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: handler)
    }

    func checkAvailability() throws -> FoundationModelAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(.deviceNotEligible):
            return .notEligibleDevice
        case .unavailable(.appleIntelligenceNotEnabled):
            return .notEnabled
        case .unavailable(.modelNotReady):
            return .modelNotReady
        case .unavailable:
            return .unsupportedOS
        }
    }

    func initializeSession(instructions: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard case .available = SystemLanguageModel.default.availability else {
            completion(.failure(PigeonError(
                code: "UNAVAILABLE",
                message: "Apple Intelligence is not available on this device.",
                details: nil
            )))
            return
        }
        session = LanguageModelSession(instructions: Instructions(instructions))
        completion(.success(()))
    }

    func generateResponse(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let session else {
            completion(.failure(PigeonError(
                code: "NO_SESSION",
                message: "Call initializeSession before generateResponse.",
                details: nil
            )))
            return
        }
        Task {
            do {
                let response = try await session.respond(to: Prompt(prompt))
                completion(.success(response.content))
            } catch {
                completion(.failure(PigeonError(
                    code: "INFERENCE_ERROR",
                    message: error.localizedDescription,
                    details: nil
                )))
            }
        }
    }
}
