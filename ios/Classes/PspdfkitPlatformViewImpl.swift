//
//  Copyright © 2024 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

import Foundation

@objc(PspdfkitPlatformViewImpl)
public class PspdfkitPlatformViewImpl: NSObject, PspdfkitWidgetControllerApi, PDFViewControllerDelegate {
    
    private var pdfViewController: PDFViewController? = nil;
    private var pspdfkitWidgetCallbacks: PspdfkitWidgetCallbacks? = nil;
    private var viewId: String? = nil;
    
    @objc public func setViewController(controller: PDFViewController){
        self.pdfViewController = controller
        self.pdfViewController?.delegate = self
    }
    
    public func pdfViewController(_ pdfController: PDFViewController, didChange document: Document?) {
        if document != nil {
            pspdfkitWidgetCallbacks?.onDocumentLoaded(documentId: document!.uid){ _ in }
        } else {
            pspdfkitWidgetCallbacks?.onDocumentError(documentId: "", error: "Laoding Document failed") {_ in }
        }
    }
    
    public func pdfViewController(_ pdfController: PDFViewController, willBeginDisplaying pageView: PDFPageView, forPageAt pageIndex: Int) {
        guard  let document = pdfViewController?.document else {
            return
        }
        pspdfkitWidgetCallbacks?.onPageChanged(documentId:document.uid , pageIndex: Int64(pageIndex)){ _ in }
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
            completion(.failure(error))
        }
    }
    
    func exportInstantJson(completion: @escaping (Result<String?, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
               completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            let json = try PspdfkitFlutterHelper.exportInstantJson(document: document)
            completion(.success(json))
        } catch {
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
            completion(.failure(error))
        }
    }
    
    func getAnnotations(pageIndex: Int64, type: String, completion: @escaping (Result<Any, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
               completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            let annotations = try PspdfkitFlutterHelper.getAnnotations(forPageIndex: PageIndex(pageIndex), andType: type, for: document)
            completion(.success(annotations))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getAllUnsavedAnnotations(completion: @escaping (Result<Any, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
               completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            let annotations = try PspdfkitFlutterHelper.getAllUnsavedAnnotations(for: document)
            completion(.success(annotations))
        } catch {
            completion(.failure(error))
        }
    }
    
    func processAnnotations(type: AnnotationType, processingMode: AnnotationProcessingMode, destinationPath: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        do {
            let success = try PspdfkitFlutterHelper.processAnnotations(ofType: "\(type)", withProcessingMode: "\(processingMode)", andDestinationPath: destinationPath, for: pdfViewController!)
            completion(.success(success))
        } catch {
            completion(.failure(error))
        }
    }
    
    func importXfdf(xfdfString: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
               completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            let success = try PspdfkitFlutterHelper.importXFDF(fromString: xfdfString, for: document)
            completion(.success(success))
        } catch {
            completion(.failure(error))
        }
    }
    
    func exportXfdf(xfdfPath: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        do {
            guard let document = pdfViewController?.document, document.isValid else {
               completion(.failure(PspdfkitApiError(code: "", message: "PDF document not found or is invalid.", details: nil)))
                return
            }
            let success = try PspdfkitFlutterHelper.exportXFDF(toPath: xfdfPath, for: document)
            completion(.success(success))
        } catch {
            completion(.failure(error))
        }
    }
    
    func save(completion: @escaping (Result<Bool, any Error>) -> Void) {
        guard let document = pdfViewController?.document, document.isValid else {
            completion(.failure(PspdfkitApiError(code: "", message: "Invalid PDF document.", details:   nil )))
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
    
    func setAnnotationConfigurations(configurations: [String : [String : Any]], completion: @escaping (Result<Bool?, any Error>) -> Void) {
        AnnotationsPresetConfigurations.setConfigurations(annotationPreset: configurations)
    }
    
    func getVisibleRect(pageIndex: Int64, completion: @escaping (Result<PdfRect, any Error>) -> Void) {
        guard let pdfViewController = pdfViewController else {
            completion(.failure(NSError(domain: "PspdfkitPlatformViewImpl", code: -1, userInfo: [NSLocalizedDescriptionKey: "PDFViewController is not set."])))
            return
        }
        let visibleRect = pdfViewController.viewState?.viewPort
        
        if visibleRect == nil {
            completion(.failure(NSError(domain: "PspdfkitPlatformViewImpl", code: -1, userInfo: [NSLocalizedDescriptionKey: "Visible rect is not set."])))
            return
        }
        
        let result: PdfRect = PdfRect(x: visibleRect!.origin.x, y: visibleRect!.origin.y, width: visibleRect!.size.width, height: visibleRect!.size.height)
        completion(.success(result))
    }
    
    func zoomToRect(pageIndex: Int64, rect: PdfRect, animated: Bool?, duration: Double?, completion: @escaping (Result<Bool, any Error>) -> Void) {
        guard let pdfViewController = pdfViewController else {
            completion(.failure(NSError(domain: "PspdfkitPlatformViewImpl", code: -1, userInfo: [NSLocalizedDescriptionKey: "PDFViewController is not set."])))
            return
        }
        
        let rectToZoom = CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
        pdfViewController.documentViewController?.zoom(toPDFRect: rectToZoom, forPageAt: Int(pageIndex), animated: animated ?? true)
        completion(.success(true))
    }
    
    func getZoomScale(pageIndex: Int64, completion: @escaping (Result<Double, any Error>) -> Void) {
        // Not implemented for iOS.
        let errormessage: String = "Not implemented for iOS."
        completion(.failure(PspdfkitApiError(code: "", message: errormessage, details: nil)))
    }
    
    @objc public func onDocumentLoaded(documentId: String){
        pspdfkitWidgetCallbacks?.onDocumentLoaded(documentId: documentId){_ in }
    }
    
    @objc public func register( binaryMessenger: FlutterBinaryMessenger, viewId: String){
        self.viewId = viewId
        pspdfkitWidgetCallbacks = PspdfkitWidgetCallbacks(binaryMessenger: binaryMessenger, messageChannelSuffix: "widget.callbacks.\(viewId)")
        PspdfkitWidgetControllerApiSetup.setUp(binaryMessenger: binaryMessenger, api: self, messageChannelSuffix:viewId)
    }
    
    @objc public func unRegister(binaryMessenger: FlutterBinaryMessenger){
        pspdfkitWidgetCallbacks = nil
        PspdfkitWidgetControllerApiSetup.setUp(binaryMessenger: binaryMessenger, api: nil, messageChannelSuffix: viewId ?? "")
    }
}
