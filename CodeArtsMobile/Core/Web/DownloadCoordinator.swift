import Foundation
import WebKit

final class DownloadCoordinator: NSObject, WKDownloadDelegate {

    private var activeDownloads: [WKDownload: URL] = [:]
    private var onFinish: ((URL) -> Void)?
    private var onFailure: ((String) -> Void)?

    func begin(onFinish: @escaping (URL) -> Void, onFailure: @escaping (String) -> Void) {
        self.onFinish = onFinish
        self.onFailure = onFailure
    }

    func attach(_ download: WKDownload) {
        download.delegate = self
    }

    func reset() {
        activeDownloads.removeAll()
        onFinish = nil
        onFailure = nil
    }

    func download(_ download: WKDownload,
                  decideDestinationUsing response: URLResponse,
                  suggestedFilename: String,
                  completionHandler: @escaping (URL?) -> Void) {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            completionHandler(nil)
            return
        }
        let safeName = suggestedFilename.isEmpty ? "codearts-download" : suggestedFilename
        var destination = directory.appendingPathComponent(safeName)
        var index = 1
        let base = destination.deletingPathExtension().lastPathComponent
        let ext = destination.pathExtension
        while FileManager.default.fileExists(atPath: destination.path) {
            let name = ext.isEmpty ? "\(base)-\(index)" : "\(base)-\(index).\(ext)"
            destination = directory.appendingPathComponent(name)
            index += 1
        }
        activeDownloads[download] = destination
        completionHandler(destination)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let destination = activeDownloads[download] else { return }
        activeDownloads.removeValue(forKey: download)
        onFinish?(destination)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        activeDownloads.removeValue(forKey: download)
        onFailure?(error.localizedDescription)
    }
}