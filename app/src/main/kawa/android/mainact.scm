
;; global variable for Activity context.
;; The correct reference is always accessible from a telnet REPL.
(define-variable *activity*)

;; exception to string converter.
;; used for displaying loading errors.
(define (exn->string (ex::java.lang.Throwable))
  (let ((buffer (open-output-string)))
    (ex:printStackTrace buffer)
    (get-output-string buffer)))

;; try loading a file and catch all error text.
(define (catchload fn)
  (let ((buffer (open-output-string)))
    (parameterize ((current-error-port buffer))
                  (load fn))
    (get-output-string buffer)))

;; the location on external storage that holds files to load.
;; This is generated from the app name in the manifest.
;; if using resources in strings.xml, change nonLocalizedLabel to labelRes.
(define (loaddir act::android.app.Activity)
  (let ((appname ((act:getPackageManager):getApplicationInfo
                  (act:getPackageName) 0):nonLocalizedLabel)
        (extstorage
         ((android.os.Environment:getExternalStorageDirectory):getAbsolutePath)))
    (string-append extstorage "/" appname)))

(define errorbox
  (lambda (act::android.app.Activity message::String)
    (act:setContentView
     (android.widget.TextView 
      act text: message))))

(define-simple-class mainact (android.app.Activity)
  ((onCreate (saved-state::android.os.Bundle))::void
   (let* ((self (this))
          (extroot (loaddir self)))
     (invoke-special android.app.Activity self 'onCreate saved-state)
     (kawa.standard.Scheme:registerEnvironment)
     (set! *activity* self)
     (try-catch 
      (begin
        (if (not (file-directory? extroot))
            (create-directory extroot))
        (let ((errtext (catchload 
                        (string-append extroot "/on-create.scm"))))
          (if (< 0 (string-length errtext))
              ;; change this to a scrollview if the error is long.
              (errorbox self errtext)
              )))
      (ex java.lang.Throwable 
          (errorbox self (exn->string ex))))
     )))
