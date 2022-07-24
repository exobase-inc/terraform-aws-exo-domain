
//
//  User Input
//

variable "domain" {
  type = string
  description = "Example: exobase.cloud or terranova.io"
}

variable "create_hosted_zone" {
  type = bool
  description = "Tells the build package if it should create the hosted zone or reference one that already exists"
}


//
//  Exobase Provided
//

variable "exo_context" {
  type = string // json:DeploymentContext
}
