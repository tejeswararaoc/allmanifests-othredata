terraform {
  backend "azurerm" {
    resource_group_name  = "CMS_PROD_01"
    storage_account_name = "prodtfstatecms"
    container_name       = "prodstatefile"
    key                  = "prod.terraform.tfstate"
    sas_token            = "sv=2022-11-02&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2024-10-27T21:42:13Z&st=2024-10-27T13:42:13Z&spr=https&sig=1UcegzA83ttvsJNlzeZmFlPt4AzmByN5VX0GzTut%2Bbc%3D"
  }
}
