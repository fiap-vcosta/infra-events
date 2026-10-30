locals {
  topic_ids = toset([
    "diagnostico-finalizado",
    "orcamento-gerado",
    "orcamento-falhou",
    "ordem-servico-aprovada",
    "estoque-reservado",
    "estoque-em-falta",
    "ordem-servico-finalizada",
    "cobranca-gerada",
    "pagamento-confirmado",
    "pagamento-recusado",
    "ordem-servico-descartada",
    "notificacoes",
  ])
}

resource "google_pubsub_topic" "catalog" {
  for_each = local.topic_ids
  name     = each.value

  message_storage_policy {
    allowed_persistence_regions = [var.region]
  }
}
