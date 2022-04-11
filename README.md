# cf2-basic-auth

Terraform module which implements BASIC Authentication using CloudFront Functions.

## Usage

```hcl
module "basic_auth" {
  source = "git@github.com:shirayee/cf2-basic-auth.git"

  username      = "foo"
  password      = "bar"
  function_name = "baz
}
```

## Inputs

| Name | Description |
| --- | --- |
| username | username for BASIC Authentication |
| password | password for BASIC Authentication |
| function_name | name of CloudFront Functions |
