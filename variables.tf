
//
//  User Input
//

variable "domain" {
  type = string
  description = "Example: exobase.cloud or terranova.io"
}


//
//  Exobase Provided
//

variable "exo_context" {
  type = string // json:DeploymentContext
}
