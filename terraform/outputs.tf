output "topic_names" {
  description = "Nome completo do tópico (projects/PROJECT/topics/ID). A chave é o id."
  value       = { for id, topic in google_pubsub_topic.catalog : id => topic.name }
}
