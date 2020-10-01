(defsystem "ps-utils"
  :version "0.1.0"
  :author "Isaac Stead"
  :license "AGPL"
  :depends-on ("alexandria"
               "parenscript")
  :components ((:module "src"
                :components
                ((:file "ps-utils"))))
  :description "Small collection of utilities for the Parenscript CL->JS transpiler")

