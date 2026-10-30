terraform {
  backend "gcs" {
    bucket = "vcosta-fiap-tech-challenge-tfstate"
    prefix = "infra-events"
  }
}
