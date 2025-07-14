//
//  AudioClipController+Save.swift
//  TRApp
//
//  Created by 82Flex on 2024/12/29.
//

import AudioClip
import Combine
import ProgressHUD
import UIKit

public extension AudioClipController {
    func _saveAction() {
        let exportSettings = _saveActionPrepare()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?._saveActionFinalize(settings: exportSettings)
        }
    }

    private func _saveActionPrepare() -> [String: Any] {
        tearDownPlayer(beforeSave: true)
        tearDownTimers()

        ProgressHUDManager.showHUD(in: view) {
            ProgressHUD.animate(
                String(localized: "Encoding", bundle: .module),
                .circleDotSpinFade,
                interaction: false
            )
            ProgressHUDManager.accessibilityAnnounce(String(localized: "Encoding", bundle: .module))
        }

        return audio.exportAudioSettings
    }

    private func _saveActionFinalize(settings: [String: Any]) {
        do {
            let savedURL = try context.saveAsTemporary(settings: settings)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                ProgressHUDManager.dismissHUD(in: view) { [weak self] in
                    guard let self else { return }
                    dismiss(animated: true) {
                        let result = AudioClipEditingResult(
                            edited: true,
                            newUrl: savedURL,
                            duration: self.context.current.value.duration,
                            errorMessage: self.errorMessage,
                            errorsCount: self.errorsCount ?? 0,
                            undoCount: self.undoCount ?? 0,
                            redoCount: self.redoCount ?? 0
                        )
                        self.completionHandler?(result)
                    }
                }
            }

        } catch {
            DispatchQueue.main.async { [weak self] in
                self?._saveActionErrorOccurred(error)
            }
        }
    }

    private func _saveActionErrorOccurred(_ error: Error) {
        ProgressHUD.failed(String(localized: "Operation Failed", bundle: .module), delay: 2.0)
        ProgressHUDManager.accessibilityAnnounce(String(localized: "Operation Failed", bundle: .module))
        ProgressHUDManager.dismissHUD(in: view, delay: 2.0) { [weak self] in
            guard let self else { return }
            presentFatalError(message: error.localizedDescription)
        }
    }
}
