/*
 * Copyright © 2024 PSPDFKit GmbH. All rights reserved.
 * <p>
 * THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
 * AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
 * UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
 * This notice may not be removed from this file.
 */
package com.pspdfkit.flutter.pspdfkit

import android.graphics.RectF
import com.pspdfkit.document.formatters.DocumentJsonFormatter
import com.pspdfkit.document.formatters.XfdfFormatter
import com.pspdfkit.document.processor.PdfProcessor
import com.pspdfkit.document.processor.PdfProcessor.ProcessorProgress
import com.pspdfkit.document.processor.PdfProcessorTask
import com.pspdfkit.flutter.pspdfkit.AnnotationConfigurationAdaptor.Companion.convertAnnotationConfigurations
import com.pspdfkit.flutter.pspdfkit.annotations.FlutterAnnotationPresetConfiguration
import com.pspdfkit.flutter.pspdfkit.api.AnnotationProcessingMode
import com.pspdfkit.flutter.pspdfkit.api.AnnotationType
import com.pspdfkit.flutter.pspdfkit.api.PdfRect
import com.pspdfkit.flutter.pspdfkit.api.PspdfkitApiError
import com.pspdfkit.flutter.pspdfkit.api.PspdfkitWidgetControllerApi
import com.pspdfkit.flutter.pspdfkit.util.DocumentJsonDataProvider
import com.pspdfkit.flutter.pspdfkit.util.Preconditions.requireNotNullNotEmpty
import com.pspdfkit.flutter.pspdfkit.util.ProcessorHelper.annotationTypeFromString
import com.pspdfkit.flutter.pspdfkit.util.ProcessorHelper.processModeFromString
import com.pspdfkit.flutter.pspdfkit.util.areValidIndexes
import com.pspdfkit.forms.ChoiceFormElement
import com.pspdfkit.forms.EditableButtonFormElement
import com.pspdfkit.forms.SignatureFormElement
import com.pspdfkit.forms.TextFormElement
import com.pspdfkit.ui.PdfUiFragment
import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers
import io.reactivex.rxjava3.disposables.Disposable
import io.reactivex.rxjava3.schedulers.Schedulers
import io.reactivex.rxjava3.subscribers.DisposableSubscriber
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.nio.charset.StandardCharsets
import java.util.Locale

class PspdfkitViewImpl : PspdfkitWidgetControllerApi {
    private var pdfUiFragment: PdfUiFragment? = null
    private var disposable: Disposable? = null

    /**
     * Sets the PdfFragment to be used by the controller.
     *
     * @param pdfFragment The PdfFragment to be used by the controller.
     */
    fun setPdfFragment(pdfFragment: PdfUiFragment?) {
        this.pdfUiFragment = pdfFragment
    }

    /**
     * Disposes the controller and releases all resources.
     */
    fun dispose() {
        pdfUiFragment = null
        disposable?.dispose()
    }

    override fun setFormFieldValue(
        value: String,
        fullyQualifiedName: String,
        callback: (Result<Boolean?>) -> Unit
    ) {
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)
        // noinspection checkResult
        document.formProvider
            .getFormElementWithNameAsync(fullyQualifiedName)
            .subscribeOn(Schedulers.computation())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe(
                { formElement ->
                    if (formElement is TextFormElement) {
                        formElement.setText(value)
                        callback(Result.success(true))
                    } else if (formElement is EditableButtonFormElement) {
                        when (value) {
                            "selected" -> {
                                formElement.select()
                                callback(Result.success(true))
                            }

                            "deselected" -> {
                                formElement.deselect()
                                callback(Result.success(true))
                            }

                            else -> {
                                callback(
                                    Result.failure(
                                        PspdfkitApiError(
                                            "Invalid value for editable button form element",
                                            "Value must be either \"selected\" or \"deselected\""
                                        )
                                    )
                                )
                            }
                        }
                    } else if (formElement is ChoiceFormElement) {
                        val selectedIndexes: List<Int> = java.util.ArrayList<Int>()
                        if (areValidIndexes(value, selectedIndexes.toMutableList())) {
                            formElement.selectedIndexes = selectedIndexes
                            callback(Result.success(true))
                        } else {
                            callback(
                                Result.failure(
                                    PspdfkitApiError(
                                        "Invalid value for choice form element",
                                        "\"value\" argument needs a list of " +
                                                "integers to set selected indexes for a choice " +
                                                "form element (e.g.: \"1, 3, 5\").",
                                    )
                                )
                            )
                        }
                    } else if (formElement is SignatureFormElement) {
                        callback(
                            Result.failure(
                                PspdfkitApiError(
                                    "Signature form elements cannot be set programmatically",
                                    "Signature form elements are not supported.",
                                )
                            )
                        )
                    } else {
                        callback(
                            Result.failure(
                                PspdfkitApiError(
                                    "Invalid form element type",
                                    "Form element with name $fullyQualifiedName is not a text, " +
                                            "editable button, choice, or signature form element."
                                )
                            )
                        )
                    }
                },
                { throwable ->
                    callback(
                        Result.failure(
                            PspdfkitApiError(
                                "Error while searching for a form element with name $fullyQualifiedName",
                                throwable.message ?: "",
                            )
                        )
                    )
                }
            ) // Form element for the given name not found.
            { callback(Result.failure(PspdfkitApiError("Form element not found", ""))) }
    }

    override fun getFormFieldValue(
        fullyQualifiedName: String,
        callback: (Result<String?>) -> Unit
    ) {
        checkNotNull(pdfUiFragment)
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)
        disposable = document.formProvider
            .getFormElementWithNameAsync(fullyQualifiedName)
            .subscribeOn(Schedulers.computation())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe(
                { formElement ->
                    when (formElement) {
                        is TextFormElement -> {
                            val text: String = formElement.text ?: ""
                            callback(Result.success(text))
                        }

                        is EditableButtonFormElement -> {
                            val isSelected: Boolean =
                                formElement.isSelected
                            callback(Result.success(if (isSelected) "selected" else "deselected"))
                        }

                        is ChoiceFormElement -> {
                            val selectedIndexes: List<Int> =
                                formElement.selectedIndexes
                            val stringBuilder = StringBuilder()
                            val iterator = selectedIndexes.iterator()
                            while (iterator.hasNext()) {
                                stringBuilder.append(iterator.next())
                                if (iterator.hasNext()) {
                                    stringBuilder.append(",")
                                }
                            }
                            callback(Result.success(stringBuilder.toString()))
                        }

                        is SignatureFormElement -> {
                            callback(
                                Result.failure(
                                    PspdfkitApiError(
                                        "Signature form elements cannot be read programmatically",
                                        "Signature form elements are not supported.",
                                    )
                                )
                            )
                        }

                        else -> {
                            callback(
                                Result.failure(
                                    PspdfkitApiError(
                                        "Invalid form element type",
                                        "Form element with name $fullyQualifiedName is not a text, " +
                                                "editable button, choice, or signature form element."
                                    )
                                )
                            )
                        }
                    }
                },
                { throwable ->
                    callback(
                        Result.failure(
                            PspdfkitApiError(
                                "Error while searching for a form element with name $fullyQualifiedName",
                                throwable.message ?: "",
                            )
                        )
                    )
                }
            ) // Form element for the given name not found.
            {
                callback(
                    Result.failure(
                        PspdfkitApiError(
                            "Form field not found.",
                            "Form element with name $fullyQualifiedName not found"
                        )
                    )
                )
            }
    }

    override fun applyInstantJson(annotationsJson: String, callback: (Result<Boolean?>) -> Unit) {
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)
        val documentJsonDataProvider = DocumentJsonDataProvider(
            requireNotNullNotEmpty(
                annotationsJson,
                "annotationsJson"
            )
        )
        // noinspection checkResult
        DocumentJsonFormatter.importDocumentJsonAsync(document, documentJsonDataProvider)
            .subscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe(
                {
                    callback(Result.success(true))
                }
            ) { throwable ->
                callback(
                    Result.failure(
                        PspdfkitApiError(
                            "Failed to apply Instant JSON",
                            throwable.message ?: "",
                        )
                    )
                )
            }
    }

    override fun exportInstantJson(callback: (Result<String?>) -> Unit) {
        checkNotNull(pdfUiFragment) { "PdfFragment is not set" }
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)
        val outputStream = ByteArrayOutputStream()

        // noinspection checkResult
        DocumentJsonFormatter.exportDocumentJsonAsync(document, outputStream)
            .subscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe(
                {
                    callback(Result.success(outputStream.toString(StandardCharsets.UTF_8.name())))
                }
            ) { throwable ->
                callback(
                    Result.failure(
                        PspdfkitApiError(
                            "Failed to export Instant JSON",
                            throwable.message ?: "",
                        )
                    )
                )
            }
    }

    override fun addAnnotation(
        jsonAnnotation: String,
        callback: (Result<Boolean?>) -> Unit
    ) {
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)
        disposable =
            document.annotationProvider.createAnnotationFromInstantJsonAsync(jsonAnnotation)
                .subscribeOn(Schedulers.computation())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(
                    {
                        callback(Result.success(true))
                    }
                ) { throwable ->
                    callback(
                        Result.failure(
                            PspdfkitApiError(
                                "Error while creating annotation",
                                throwable.message ?: "",
                            )
                        )
                    )
                }
    }

    override fun removeAnnotation(jsonAnnotation: String, callback: (Result<Boolean?>) -> Unit) {
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)
        //Annotation from JSON.
        val annotation = document.annotationProvider.createAnnotationFromInstantJson(jsonAnnotation)
        document.annotationProvider.removeAnnotationFromPage(annotation)
        callback(Result.success(true))
    }

    override fun getAnnotations(pageIndex: Long, type: String, callback: (Result<Any>) -> Unit) {
        checkNotNull(pdfUiFragment) { "PdfFragment is not set" }
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)

        val annotationJsonList = ArrayList<String>()
        // noinspection checkResult
        document.annotationProvider.getAllAnnotationsOfTypeAsync(
            AnnotationTypeAdapter.fromString(
                type
            ),
            pageIndex.toInt(), 1
        )
            .subscribeOn(Schedulers.computation())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe(
                { annotation ->
                    annotationJsonList.add(annotation.toInstantJson())
                },
                { throwable ->
                    callback(
                        Result.failure(
                            PspdfkitApiError(
                                "Error while retrieving annotation of type $type",
                                throwable.message ?: "",
                            )
                        )
                    )
                },
                {
                    callback(Result.success(annotationJsonList))
                }
            )
    }

    override fun getAllUnsavedAnnotations(callback: (Result<Any>) -> Unit) {
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)
        val outputStream = ByteArrayOutputStream()

        disposable = DocumentJsonFormatter.exportDocumentJsonAsync(document, outputStream)
            .subscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe({
                val jsonString: String = outputStream.toString()
                callback(Result.success(jsonString))
            }, { throwable ->
                callback(
                    Result.failure(
                        PspdfkitApiError(
                            "Error while getting unsaved JSON annotations.",
                            throwable.message ?: "",
                        )
                    )
                )
            })
    }

    override fun processAnnotations(
        type: AnnotationType,
        processingMode: AnnotationProcessingMode,
        destinationPath: String,
        callback: (Result<Boolean>) -> Unit
    ) {
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)
        // Get the annotation type and processing mode.
        val annotationType = annotationTypeFromString(
            type.name.toLowerCase(Locale.getDefault())
        )
        val annotationProcessingMode =
            processModeFromString(processingMode.name.toLowerCase(Locale.getDefault()))
        val outputPath = File(destinationPath)

        if (outputPath.parentFile?.exists() != true && outputPath.parentFile?.mkdirs() != true) {
            callback(
                Result.failure(
                    PspdfkitApiError(
                        "Invalid output path",
                        "Output path is invalid: $outputPath"
                    )
                )
            )
            return
        }
        // Check if we need to process all annotations or only annotations of a specific type.
        val task = if (annotationType == com.pspdfkit.annotations.AnnotationType.NONE) {
            PdfProcessorTask.fromDocument(document).changeAllAnnotations(annotationProcessingMode)
        } else {
            PdfProcessorTask.fromDocument(document)
                .changeAnnotationsOfType(annotationType, annotationProcessingMode)
        }
        disposable = PdfProcessor.processDocumentAsync(task, outputPath)
            .subscribeOn(Schedulers.io())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribeWith(object : DisposableSubscriber<ProcessorProgress?>() {
                override fun onComplete() {
                    callback(Result.success(true))
                }

                override fun onNext(t: ProcessorProgress?) {
                    // No-op
                }

                override fun onError(t: Throwable) {
                    callback(
                        Result.failure(
                            PspdfkitApiError(
                                "Error while processing annotations",
                                t.message ?: "",
                            )
                        )
                    )
                }
            })
    }

    override fun importXfdf(xfdfPath: String, callback: (Result<Boolean>) -> Unit) {
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)
        val dataProvider = DocumentJsonDataProvider(xfdfPath)
        // The async parse method is recommended (so you can easily offload parsing from the UI thread).
        disposable = XfdfFormatter.parseXfdfAsync(document, dataProvider)
            .subscribeOn(Schedulers.io()) // Specify the thread on which to parse XFDF.
            .subscribe { annotations ->
                // Annotations parsed from XFDF aren't added to the document automatically.
                // You need to add them manually.
                for (annotation in annotations) {
                    document.annotationProvider.addAnnotationToPage(annotation)
                }
            }
    }

    override fun exportXfdf(xfdfPath: String, callback: (Result<Boolean>) -> Unit) {
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)

        // Output stream pointing to the XFDF file into which to write the data.
        val outputStream = FileOutputStream(xfdfPath)

        // The async `write` method is recommended (so you can easily offload writing from the UI thread).
        disposable = XfdfFormatter.writeXfdfAsync(
            document,
            listOf(),
            listOf(),
            outputStream
        )
            .subscribeOn(Schedulers.io()) // Specify the thread on which to write XFDF.
            .subscribe(
                {
                    // XFDF was successfully written.
                    callback(Result.success(true))
                },
                { throwable ->
                    // An error occurred while writing XFDF.
                    callback(
                        Result.failure(
                            PspdfkitApiError(
                                "Error while exporting XFDF",
                                throwable.message ?: "",
                            )
                        )
                    )
                }
            )
    }

    override fun save(callback: (Result<Boolean>) -> Unit) {
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)
        disposable = document.saveIfModifiedAsync()
            .subscribeOn(Schedulers.computation())
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe(
                {
                    callback(Result.success(true))
                }
            ) { throwable ->
                callback(
                    Result.failure(
                        PspdfkitApiError(
                            "Error while saving document",
                            throwable.message ?: "",
                        )
                    )
                )
            }
    }

    override fun setAnnotationConfigurations(
        configurations: Map<String, Map<String, Any>>,
        callback: (Result<Boolean?>) -> Unit
    ) {
        val parsedConfigurations: List<FlutterAnnotationPresetConfiguration> =
            convertAnnotationConfigurations(pdfUiFragment!!.requireContext(), configurations)

        val pdfFragment = pdfUiFragment?.pdfFragment

        for (config in parsedConfigurations) {
            if (config.annotationTool != null && config.variant != null) {
                pdfFragment?.annotationConfiguration?.put(
                    config.annotationTool, config.variant, config.configuration
                )
            }
            if (config.annotationTool != null && config.type == null) {
                pdfFragment?.annotationConfiguration?.put(
                    config.annotationTool, config.configuration
                )
            }
            if (config.type != null) {
                pdfFragment?.annotationConfiguration?.put(
                    config.type, config.configuration
                )
            }
        }
        callback(Result.success(true))
    }

    override fun getVisibleRect(pageIndex: Long, callback: (Result<PdfRect>) -> Unit) {
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)

        if (pageIndex < 0 || pageIndex >= document.pageCount) {
            callback(
                Result.failure(
                    PspdfkitApiError(
                        "Invalid page index",
                        "Page index must be in the range [0, ${document.pageCount})"
                    )
                )
            )
        } else {
            val visiblePdfRect = RectF()
            pdfUiFragment?.pdfFragment?.getVisiblePdfRect(visiblePdfRect, pageIndex.toInt())
            val pdfRect = PdfRect(
                visiblePdfRect.left.toDouble(),
                visiblePdfRect.top.toDouble(),
                visiblePdfRect.width().toDouble(),
                visiblePdfRect.height().toDouble()
            )
            callback(Result.success(pdfRect))
        }
    }

    override fun zoomToRect(
        pageIndex: Long,
        rect: PdfRect,
        animated: Boolean?,
        duration: Double?,
        callback: (Result<Boolean>) -> Unit
    ) {
        checkNotNull(pdfUiFragment) { "PdfFragment is not set" }
        try {
            val x = requireNotNull(rect.x)
            val y = requireNotNull(rect.y)
            val width = requireNotNull(rect.width)
            val height = requireNotNull(rect.height)
            val zooRect =
                RectF(x.toFloat(), y.toFloat(), (x + width).toFloat(), (y + height).toFloat())
            pdfUiFragment?.pdfFragment?.zoomTo(zooRect, pageIndex.toInt(), duration?.toLong() ?: 0)
            callback(Result.success(true))
        } catch (e: Exception) {
            callback(
                Result.failure(
                    PspdfkitApiError(
                        "Error while zooming to rect",
                        e.message ?: ""
                    )
                )
            )
        }
    }

    override fun getZoomScale(pageIndex: Long, callback: (Result<Double>) -> Unit) {
        val document = requireNotNull(pdfUiFragment?.pdfFragment?.document)
        if (pageIndex < 0 || pageIndex >= document.pageCount) {
            callback(
                Result.failure(
                    PspdfkitApiError(
                        "Invalid page index",
                        "Page index must be in the range [0, ${document.pageCount})"
                    )
                )
            )
        } else {
            val zoomScale = pdfUiFragment?.pdfFragment?.getZoomScale(pageIndex.toInt())
            if (zoomScale != null) {
                callback(Result.success(zoomScale.toDouble()))
            } else {
                callback(
                    Result.failure(
                        PspdfkitApiError(
                            "Error while getting zoom scale",
                            "Zoom scale is null"
                        )
                    )
                )
            }
        }
    }
}