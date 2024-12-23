//
//  Copyright © 2024 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//
import Foundation
import PSPDFKit

@objc(PspdfkitApiImpl)
public class PspdfkitApiImpl: NSObject, PspdfkitApi, PDFViewControllerDelegate, InstantClientDelegate {

    private let PSPDFSettingKeyHybridEnvironment =  SDK.Setting.init(rawValue: "com.pspdfkit.hybrid-environment")
    private var pdfViewController: PDFViewController? = nil;
    private var messenger: FlutterBinaryMessenger? = nil;
    private var pspdfkitApiCallbacks: PspdfkitFlutterApiCallbacks? = nil;
    
    func getFrameworkVersion(completion: @escaping (Result<String?, any Error>) -> Void) {
        let versionString:String = PSPDFKit.SDK.versionNumber
        completion(.success(versionString))
    }
    
    func setLicenseKey(licenseKey: String?, completion: @escaping (Result<Void, any Error>) -> Void) {
        SDK.setLicenseKey(licenseKey, options: [PSPDFSettingKeyHybridEnvironment:"Flutter"])
    }
    
    func setLicenseKeys(androidLicenseKey: String?, iOSLicenseKey: String?, webLicenseKey: String?, completion: @escaping (Result<Void, any Error>) -> Void) {
        SDK.setLicenseKey(iOSLicenseKey, options: [PSPDFSettingKeyHybridEnvironment:"Flutter"])
    }
    
    func present(document: String, configuration: [String : Any]?, completion: @escaping (Result<Bool?, any Error>) -> Void) {
        let documentPath = document
        if documentPath.isEmpty {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document path may not be nil or empty."])
            completion(.failure(error))
            return
        }
        
        let configurationDictionary = PspdfkitFlutterConverter.processConfigurationOptionsDictionary(forPrefix: configuration ?? [:])
        
        guard let document = PspdfkitFlutterHelper.document(fromPath: documentPath) else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document is missing or invalid."])
            completion(.failure(error))
            return
        }
        
        // Unlock password protected document.
        PspdfkitFlutterHelper.unlock( document:document, dictionary: configuration)
        
        let isImageDocument = PspdfkitFlutterHelper.isImageDocument(documentPath)
        let pdfConfiguration = PspdfkitFlutterConverter.configuration(configurationDictionary, isImageDocument: isImageDocument)
        
        self.pdfViewController = PDFViewController(document: document, configuration: pdfConfiguration)
        self.setupViewController(configurationDictionary: configurationDictionary) { result in
            // Set measurements value configurations
            if let measurementsValue = configurationDictionary["measurementValueConfigurations"] as? [[String: Any]] {
                for measurementValue in measurementsValue {
                    _ = PspdfkitMeasurementConvertor.addMeasurementValueConfiguration(document: self.pdfViewController!.document!, configuration: measurementValue as NSDictionary)
                }
            }
            completion(result)
        }
    }
    
    func presentInstant(serverUrl: String, jwt: String, configuration: [String : Any]?, completion: @escaping (Result<Bool?, any Error>) -> Void) {
        guard !serverUrl.isEmpty else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Server URL path may not be nil or empty."])
            completion(.failure(error))
            return
        }
        
        guard !jwt.isEmpty else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "JWT may not be nil or empty."])
            completion(.failure(error))
            return
        }
        
        let configurationDictionary = PspdfkitFlutterConverter.processConfigurationOptionsDictionary(forPrefix: configuration ?? [:])
        let enableInstantComments = configurationDictionary["enableInstantComments"] as? Bool ?? false
        let pdfConfiguration = PspdfkitFlutterConverter.configuration(configurationDictionary, isImageDocument: false)
        let documentInfo = InstantDocumentInfo(serverURL: URL(string: serverUrl)!, url: URL(string: serverUrl)!, jwt: jwt)
        
        do {
            let instantViewController = try InstantDocumentViewController(documentInfo: documentInfo, configurations: pdfConfiguration.configurationUpdated { builder in
                if enableInstantComments {
                    var editableAnnotationTypes = builder.editableAnnotationTypes
                    editableAnnotationTypes!.insert(Annotation.Tool.instantCommentMarker)
                    builder.editableAnnotationTypes = editableAnnotationTypes
                }
            })
            self.pdfViewController = instantViewController
            
            let client = instantViewController.client
            client.delegate = self
            
            self.pdfViewController = instantViewController
            self.setupViewController(configurationDictionary: configurationDictionary) { result in
                // Set measurements value configuration
                if let measurementsValue = configurationDictionary["measurementValueConfigurations"] as? [[String: Any]] {
                    for measurementValue in measurementsValue {
                        _ = PspdfkitMeasurementConvertor.addMeasurementValueConfiguration(document: self.pdfViewController!.document!,
                                                                                          configuration: measurementValue as NSDictionary)
                    }
                }
                completion(result)
            }
        } catch {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create InstantDocumentViewController: \(error.localizedDescription)"])
            completion(.failure(error))
            return
        }
    }
    
    func setFormFieldValue(value: String, fullyQualifiedName: String, completion: @escaping (Result<Bool?, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
                completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            
            let success = try PspdfkitFlutterHelper.setFormFieldValue(value, forFieldWithFullyQualifiedName: fullyQualifiedName, for: document)
            completion(.success(success))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getFormFieldValue(fullyQualifiedName: String, completion: @escaping (Result<String?, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
                completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            
            let value = try PspdfkitFlutterHelper.getFormFieldValue(forFieldWithFullyQualifiedName: fullyQualifiedName, for: document)
            completion(.success(value as? String))
        } catch {
            completion(.failure(error))
        }
    }
    
    func applyInstantJson(annotationsJson: String, completion: @escaping (Result<Bool?, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
                completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            let success = try PspdfkitFlutterHelper.applyInstantJson(annotationsJson: annotationsJson, document: document)
            pdfViewController!.reloadData()
            completion(.success(success))
        } catch {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to apply Instant JSON: \(error.localizedDescription)"])
            completion(.failure(error))
        }
    }
    
    func exportInstantJson(completion: @escaping (Result<String?, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
                completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            
            let annotationsJson = try PspdfkitFlutterHelper.exportInstantJson(document: document)
            completion(.success(annotationsJson))
        } catch {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to export Instant JSON: \(error.localizedDescription)"])
            completion(.failure(error))
        }
    }
    
    func addAnnotation(jsonAnnotation: String, completion: @escaping (Result<Bool?, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
                completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            
            let success = try PspdfkitFlutterHelper.addAnnotation(jsonAnnotation, for: document)
            completion(.success(success))
        } catch {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to add annotation: \(error.localizedDescription)"])
            completion(.failure(error))
        }
    }
    
    func removeAnnotation(jsonAnnotation: String, completion: @escaping (Result<Bool?, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
                completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            
            let success = try PspdfkitFlutterHelper.removeAnnotation(jsonAnnotation, for: document)
            completion(.success(success))
        } catch {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to remove annotation: \(error.localizedDescription)"])
            completion(.failure(error))
        }
    }
    
    func getAnnotations(pageIndex: Int64, type: String, completion: @escaping (Result<Any?, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
                completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            let annotations = try PspdfkitFlutterHelper.getAnnotations(forPageIndex: PageIndex(Int(pageIndex)), andType: type, for: document)
            completion(.success(annotations))
        } catch {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get annotations: \(error.localizedDescription)"])
            completion(.failure(error))
        }
    }
    
    func getAllUnsavedAnnotations(completion: @escaping (Result<Any?, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
                completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            
            let annotations = try PspdfkitFlutterHelper.getAllUnsavedAnnotations(for: document)
            completion(.success(annotations))
        } catch {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get all unsaved annotations: \(error.localizedDescription)"])
            completion(.failure(error))
        }
    }
    
    func processAnnotations(type: AnnotationType, processingMode: AnnotationProcessingMode, destinationPath: String, completion: @escaping (Result<Bool?, any Error>) -> Void) {
        do {
            let success = try PspdfkitFlutterHelper.processAnnotations(ofType: "\(type)", withProcessingMode: "\(processingMode)", andDestinationPath: destinationPath, for: pdfViewController!)
            completion(.success(success))
        } catch {
            completion(.failure(error))
        }
    }
    
    func importXfdf(xfdfString: String, completion: @escaping (Result<Bool?, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
                completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            
            let success = try PspdfkitFlutterHelper.importXFDF(fromString: xfdfString, for: document)
            completion(.success(success))
        } catch {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to import XFDF: \(error.localizedDescription)"])
            completion(.failure(error))
        }
    }
    
    func exportXfdf(xfdfPath: String, completion: @escaping (Result<Bool?, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
                completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            
            let success = try PspdfkitFlutterHelper.exportXFDF(toPath: xfdfPath, for: document)
            completion(.success(success))
        } catch {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to export XFDF: \(error.localizedDescription)"])
            completion(.failure(error))
        }
    }
    
    func save(completion: @escaping (Result<Bool?, any Error>) -> Void) {
        guard let document = pdfViewController?.document, document.isValid else {
            completion(.failure(NSError(domain: "PspdfkitPlatformViewImpl", code: -1, userInfo: [NSLocalizedDescriptionKey: "PDF document not found or is invalid."])))
            return
        }
        document.save() { Result in
            if case .success = Result {
                completion(.success(true))
            } else {
                let error = PspdfkitApiError(code: "", message: "Failed to save PDF document.", details:   nil )
                completion(.failure(error))
            }
        }
    }
    
    func setDelayForSyncingLocalChanges(delay: Double, completion: @escaping (Result<Bool?, any Error>) -> Void) {
        // if pdfViewController is an instance of InstantDocumentViewController, then we can set the delay.
        if let instantDocumentViewController = pdfViewController as? InstantDocumentViewController {
            instantDocumentViewController.documentDescriptor.delayForSyncingLocalChanges = delay
            completion(.success(true))
        } else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Delay can only be set for Instant documents"])
            completion(.failure(error))
        }
    }
    
    func setListenToServerChanges(listen: Bool, completion: @escaping (Result<Bool?, any Error>) -> Void) {
        
        if let instantDocumentViewController = pdfViewController as? InstantDocumentViewController {
            instantDocumentViewController.shouldListenForServerChangesWhenVisible = listen
            completion(.success(true))
        } else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "listenToServerChanges can only be set for Instant documents"])
            completion(.failure(error))
        }
    }
    
    func syncAnnotations(completion: @escaping (Result<Bool?, any Error>) -> Void) {
        // if pdfViewController is an instance of InstantDocumentViewController, then we can set the delay.
        if let instantDocumentViewController = pdfViewController as? InstantDocumentViewController {
            instantDocumentViewController.documentDescriptor.sync()
            completion(.success(true))
        } else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "syncAnnotations can only be called on Instant document"])
            completion(.failure(error))
        }
    }
    
    func setAnnotationPresetConfigurations(configurations: [String : Any?], completion: @escaping (Result<Bool?, any Error>) -> Void) {
        if let annotationConfigurations = configurations["annotationConfigurations"] as? Dictionary<String, Dictionary<String, Any>> {
            AnnotationsPresetConfigurations.setConfigurations(annotationPreset: annotationConfigurations)
            completion(.success(true))
        } else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid annotation configurations."])
            completion(.failure(error))
        }
    }
    
    func getTemporaryDirectory(completion: @escaping (Result<String, any Error>) -> Void) {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if let tempDirectory = paths.first {
            completion(.success(tempDirectory))
        } else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to find temporary directory."])
            completion(.failure(error))
        }
    }
    
    func getAuthorName(completion: @escaping (Result<String, any Error>) -> Void) {
        let authorName = pdfViewController?.document?.defaultAnnotationUsername
        completion(.success(authorName ?? ""))
    }
    
    func generatePdf(pages: [[String : Any]], outputPath: String, completion: @escaping (Result<String?, any Error>) -> Void) {
       
        let pageAdaptor: PspdfkitPageConvertor = PspdfkitPageConvertor()
        let convertedPages = pageAdaptor.convert(pages: pages)
        let configuration = Processor.Configuration()
        
        guard let processedDocumentURL = PspdfkitFlutterHelper.writableFileURL(withPath: outputPath, override: true, copyIfNeeded: true) else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to create output file."])
            completion(.failure(error))
            return
        }
        
        
        for (index, page) in convertedPages.enumerated(){
            configuration.addNewPage(at: UInt(index) , configuration: page)
        }
        
        // Save to a new PDF file.
        do {
            try Processor(configuration: configuration, securityOptions: nil).write(toFileURL: processedDocumentURL)
            completion(.success(processedDocumentURL.relativePath))
        } catch {
           completion(.failure(error))
        }
    }
    
    func generatePdfFromHtmlString(html: String, outPutFile: String, options: [String : Any]?, completion: @escaping (Result<String?, any Error>) -> Void) {

        let outputPath = outPutFile
        guard let processedDocumentURL = PspdfkitFlutterHelper.writableFileURL(withPath: outputPath, override: true, copyIfNeeded: false) else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to create output file at \(outputPath)."])
            completion(.failure(error))
            return
        }
        
        var generatePdfOptions:[String: Any] = [:]
        
        if(options?["documentTitle"] != nil){
            generatePdfOptions[PSPDFProcessorDocumentTitleKey] = options?["documentTitle"]
        }
        
        if(options?["numberOfPages"] != nil){
            generatePdfOptions[PSPDFProcessorNumberOfPagesKey] = options?["numberOfPages"]
        }
        
        generatePdfOptions  = generatePdfOptions as [String: Any]
        
        Processor.generatePDF(fromHTMLString: html, outputFileURL: processedDocumentURL, options: generatePdfOptions) { outputURL, error in
            if let outputURL = outputURL {
                completion(.success(processedDocumentURL.relativePath))
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }
    
    func generatePdfFromHtmlUri(htmlUri: String, outPutFile: String, options: [String : Any]?, completion: @escaping (Result<String?, any Error>) -> Void) {
    
        let htmlURLString = htmlUri
        let outputPath = outPutFile
        guard let processedDocumentURL = PspdfkitFlutterHelper.writableFileURL(withPath: outputPath, override: true, copyIfNeeded: false) else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to find temporary directory."])
            completion(.failure(error))
            return
        }
        guard let htmlURL = URL(string: htmlURLString) else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid HTML URL."])
            completion(.failure(error))
            return
        }
        
        var processorOptions: [String: Any] = [:]
        
        if (options?["numberOfPage"]) != nil {
            let numberOfPage = options?["numberOfPage"] as! Int
            processorOptions[PSPDFProcessorNumberOfPagesKey] = numberOfPage
        } else {
            let numberOfPages = 10
            processorOptions[PSPDFProcessorNumberOfPagesKey] = numberOfPages
        }
        
        if (options?["documentTitle"]) != nil {
            let documentTitle = options?["documentTitle"] as! String
            processorOptions[PSPDFProcessorDocumentTitleKey] = documentTitle
        } else {
            processorOptions[PSPDFProcessorDocumentTitleKey] = ""
        }
        
        Processor.generatePDF(from:htmlURL,outputFileURL: processedDocumentURL, options: processorOptions) { outputURL, error in
            if let outputURL = outputURL {
                completion(.success(processedDocumentURL.relativePath))
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }
    
    public  func instantClient(_ instantClient: InstantClient, didFinishDownloadFor documentDescriptor: any InstantDocumentDescriptor) {
        pspdfkitApiCallbacks?.onInstantDownloadFinished(documentId: documentDescriptor.identifier){_ in}
        
    }
    
    public func instantClient(_ instantClient: InstantClient, documentDescriptor: any InstantDocumentDescriptor, didFailDownloadWithError error: any Error) {
        pspdfkitApiCallbacks?.onInstantDownloadFailed(documentId: documentDescriptor.identifier, error: error.localizedDescription){_ in }
    }
    
    public func instantClient(_ instantClient: InstantClient, didFailAuthenticationFor documentDescriptor: any InstantDocumentDescriptor) {
        pspdfkitApiCallbacks?.onInstantAuthenticationFailed(documentId: documentDescriptor.identifier, error: "Authentication failed"){_ in }
    }
    
    public func instantClient(_ instantClient: InstantClient, documentDescriptor: any InstantDocumentDescriptor, didFinishReauthenticationWithJWT validJWT: String) {
        pspdfkitApiCallbacks?.onInstantAuthenticationFinished(documentId: documentDescriptor.identifier, validJWT: validJWT){_ in}
    }
    
    public  func instantClient(_ instantClient: InstantClient, documentDescriptor: any InstantDocumentDescriptor, didFailReauthenticationWithError error: any Error) {
        pspdfkitApiCallbacks?.onInstantAuthenticationFailed(documentId: documentDescriptor.identifier, error: error.localizedDescription){_ in }
    }
    
    public func instantClient(_ instantClient: InstantClient, didFinishSyncFor documentDescriptor: any InstantDocumentDescriptor) {
        pspdfkitApiCallbacks?.onInstantSyncFinished(documentId: documentDescriptor.identifier){_ in }
    }
    
    public func instantClient(_ instantClient: InstantClient, documentDescriptor: any InstantDocumentDescriptor, didFailSyncWithError error: any Error) {
        pspdfkitApiCallbacks?.onInstantSyncFailed(documentId: documentDescriptor.identifier, error: documentDescriptor.identifier){_ in }
    }
    
    public func instantClient(_ instantClient: InstantClient, didBeginSyncFor documentDescriptor: any InstantDocumentDescriptor) {
        pspdfkitApiCallbacks?.onInstantSyncStarted(documentId: documentDescriptor.identifier){ _ in}
    }
    
    public func pdfViewControllerWillDismiss(_ pdfController: PDFViewController) {
        pspdfkitApiCallbacks?.onPdfViewControllerWillDismiss() { _ in }
    }
    
    public func pdfViewControllerDidDismiss(_ pdfController: PDFViewController) {
        pspdfkitApiCallbacks?.onPdfViewControllerDidDismiss(){ _ in }
    }
    
    public func pdfViewController(_ pdfController: PDFViewController, didChange document: Document?) {
        if let document {
            pspdfkitApiCallbacks?.onDocumentLoaded(documentId: document.uid){ _ in }
        }
    }
    
    func setupViewController(configurationDictionary: [AnyHashable: Any], completion: @escaping (Result<Bool?, Error>) -> Void) {
        guard let pdfViewController = self.pdfViewController else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "PDFViewController is not initialized."])
            completion(.failure(error))
            return
        }
        
        pdfViewController.appearanceModeManager.appearanceMode = PspdfkitFlutterConverter.appearanceMode(configurationDictionary)
        pdfViewController.pageIndex = PspdfkitFlutterConverter.pageIndex(configurationDictionary)
        pdfViewController.delegate = self
        
        if !configurationDictionary.isEmpty {
            if let leftBarButtonItems = configurationDictionary["leftBarButtonItems"] as? [String] {
                PspdfkitFlutterHelper.setLeftBarButtonItems(leftBarButtonItems, for: pdfViewController)
            }
            if let rightBarButtonItems = configurationDictionary["rightBarButtonItems"] as? [String] {
                PspdfkitFlutterHelper.setRightBarButtonItems(rightBarButtonItems, for: pdfViewController)
            }
            if let invertColors = configurationDictionary["invertColors"] as? Bool {
                pdfViewController.appearanceModeManager.appearanceMode = invertColors ? .night : []
            }
            if let toolbarTitle = configurationDictionary["toolbarTitle"] as? String {
                PspdfkitFlutterHelper.setToolbarTitle(toolbarTitle, for: pdfViewController)
            }
        }
        
        let navigationController = PDFNavigationController(rootViewController: pdfViewController)
        navigationController.modalPresentationStyle = .fullScreen
        if let presentingViewController = UIApplication.shared.delegate?.window??.rootViewController {
            presentingViewController.present(navigationController, animated: true) {
                completion(.success(true))
            }
        } else {
            let error = NSError(domain: "FlutterError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Presenting view controller is not available."])
            completion(.failure(error))
        }
    }
    
    func checkAndroidWriteExternalStoragePermission(completion: @escaping (Result<Bool?, any Error>) -> Void) {
        completion(.failure(PspdfkitApiError(code: "", message: "Not implements", details: nil)))
    }
    
    func requestAndroidWriteExternalStoragePermission(completion: @escaping (Result<AndroidPermissionStatus, any Error>) -> Void) {
        completion(.failure(PspdfkitApiError(code: "", message: "Not implements", details: nil)))
    }
    
    func openAndroidSettings(completion: @escaping (Result<Void, any Error>) -> Void) {
        completion(.failure(PspdfkitApiError(code: "", message: "Not implements", details: nil)))
    }
    
    // Setup pigeon message channel.
    @objc public func register( binaryMessenger: FlutterBinaryMessenger){
        messenger = binaryMessenger
        PspdfkitApiSetup.setUp(binaryMessenger: binaryMessenger, api: self, messageChannelSuffix: "pspdfkit")
        pspdfkitApiCallbacks = PspdfkitFlutterApiCallbacks(binaryMessenger: binaryMessenger, messageChannelSuffix: "pspdfkit")
    }
    
    // Unregister pigeon message channel.
    @objc public func unRegister(){
        if messenger != nil {
            PspdfkitApiSetup.setUp(binaryMessenger: messenger!, api: nil)
        }
        pspdfkitApiCallbacks = nil
    }
}
