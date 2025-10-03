terraform {
  backend "azurerm" {}
}

// This file intentionally contains an empty azurerm backend block.
// Actual backend settings are supplied at init time via a local
// `backend.config` file and should not be committed.
