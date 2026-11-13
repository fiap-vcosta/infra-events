# ADR 001: Consumo Pub/Sub por pull (worker)

**Data:** 12 de novembro de 2026  
**Status:** Aceito  
**Autores:** Victor Costa

## 1. Contexto e Problema

A Saga coreografada usa Google Pub/Sub entre os serviços. O Pub/Sub oferece **push** (HTTP para um endpoint) e **pull** (o cliente busca mensagens). Os serviços .NET já rodam no GKE com background workers; push exigiria expor rotas internas só para mensageria e cuidar de autenticação no endpoint.

O problema a ser resolvido é: **Push ou pull para consumir os eventos da oficina?**

## 2. Decisão

- **Pull** via API do subscriber (`Pull` em loop no worker), encapsulado no pacote `building-blocks` (`GooglePubSubTransport` + hosted worker).
- Este repo (`infra-events`) cria só os **tópicos**.
- **Subscription**, IAM de subscriber e tópico de **dead-letter** ficam no Terraform do serviço consumidor (P9).
- Publisher: `roles/pubsub.publisher` no tópico, no Terraform do serviço que publica.
- Consumidores são **idempotentes**; nack / DLQ para falha persistente.

## 3. Justificativa

* O pod já está no cluster; pull não precisa de URL pública nem de rota `/system` extra só para Pub/Sub.
* Funciona igual no compose com emulador e na GCP.
* Alinha ao desenho de Saga sem orquestrador: cada serviço puxa o que assinou.

## 4. Alternativas Consideradas

* **Push para Service no GKE:** possível com auth; mais superfície HTTP e config de push endpoint — rejeitado para o escopo.
* **Cloud Functions / Eventarc por mensagem:** outro runtime para operar na demo — rejeitado.

## 5. Consequências

### Positivas
* Um padrão de worker em todos os consumidores.
* DLQ e retries ficam no modelo de subscription do serviço.

### Negativas / Riscos
* Worker parado = backlog até o deploy/HPA recuperar.
  * *Mitigação:* health do serviço; monitores de DLQ/idade na janela Datadog.
* Pull com polling curto gera chamadas ociosas.
  * *Mitigação:* aceitável na demo; volume baixo.
