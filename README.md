# infra-events

Terraform dos tópicos Pub/Sub da oficina na GCP — Tech Challenge FIAP ([fiap-vcosta](https://github.com/fiap-vcosta)).

## Escopo

- 12 tópicos Pub/Sub. Cada evento de domínio tem o seu; `OrcamentoDisponivel` e `CobrancaPixDisponivel` compartilham `notificacoes`
- Persistência de mensagem restrita a `us-central1`
- Output `topic_names`: mapa do id para o nome completo `projects/{project}/topics/{id}`
- Região `us-central1`, projeto `vcosta-fiap-tech-challenge`
- State remoto em GCS (o bucket é gerenciado pelo `infra-bootstrap`; `tf-destroy` não o apaga)

Quem publica recebe `roles/pubsub.publisher` no Terraform do próprio serviço. Subscription, `roles/pubsub.subscriber` e o tópico de dead-letter nascem no Terraform do serviço que consome. Este stack não cria subscription nem binding de IAM.

Payloads e chaves de idempotência: [`e2e` / `docs/eventos.md`](https://github.com/fiap-vcosta/e2e/blob/main/docs/eventos.md).

Root module: [`terraform/`](terraform/).

## Tópicos

| Evento | Id | Publicador | Consumidores |
|--------|----|------------|--------------|
| `DiagnosticoFinalizado` | `diagnostico-finalizado` | `ordem-servico-service` | `orcamento-service` |
| `OrcamentoGerado` | `orcamento-gerado` | `orcamento-service` | `ordem-servico-service` |
| `OrcamentoFalhou` | `orcamento-falhou` | `orcamento-service` | `ordem-servico-service` |
| `OrdemServicoAprovada` | `ordem-servico-aprovada` | `ordem-servico-service` | `estoque-service` |
| `EstoqueReservado` | `estoque-reservado` | `estoque-service` | `ordem-servico-service` |
| `EstoqueEmFalta` | `estoque-em-falta` | `estoque-service` | `ordem-servico-service` |
| `OrdemServicoFinalizada` | `ordem-servico-finalizada` | `ordem-servico-service` | `estoque-service`, `orcamento-service` |
| `CobrancaGerada` | `cobranca-gerada` | `orcamento-service` | `ordem-servico-service` |
| `PagamentoConfirmado` | `pagamento-confirmado` | `orcamento-service` | `ordem-servico-service` |
| `PagamentoRecusado` | `pagamento-recusado` | `orcamento-service` | `ordem-servico-service` |
| `OrdemServicoDescartada` | `ordem-servico-descartada` | `ordem-servico-service` | `orcamento-service`, `estoque-service` |
| `OrcamentoDisponivel`, `CobrancaPixDisponivel` | `notificacoes` | `orcamento-service` | nenhum |

`administrativo-service` e `autenticacao-service` não publicam nem consomem estes tópicos. `notificacoes` não tem consumidor de aplicação; a evidência é a mensagem no tópico.

## State (GCS)

| Item | Valor |
|------|--------|
| Bucket | `vcosta-fiap-tech-challenge-tfstate` |
| Prefix deste repo | `infra-events` |
| Quem lê este prefix | Terraform de cada serviço que publica ou consome (`topic_names`) |

Este stack não lê o state de outro repositório. Não há org var para id de tópico.

## CI vs CD

| Tipo | Quando | Automático? |
|------|--------|-------------|
| **CI** `fmt` + `validate` | PR / push | Sim |
| **CI** `plan` (OIDC) | PR | Sim |
| **`tf-apply` / `tf-destroy`** | Janela da demo | Só manual (`workflow_dispatch`) |

Merge em `main` **nunca** cria tópico.

Os workflows autenticam com as org vars `GCP_WORKLOAD_IDENTITY_PROVIDER` e `GCP_SERVICE_ACCOUNT_EMAIL`. `project_id` e `region` são defaults em [`terraform/variables.tf`](terraform/variables.tf).

## Roles da SA `github-actions` (least-privilege)

A service account, o OIDC e as roles são código no `infra-bootstrap`. Deste conjunto, este stack usa:

- role customizada `ciPubSubAdmin` — criar, alterar e apagar tópicos
- no bucket de state: `roles/storage.objectAdmin`

## Comandos locais

```bash
cd terraform
terraform fmt -check
terraform init -backend=false
terraform validate
```

Plan/apply local exigem ADC (`gcloud auth application-default login`) e backend GCS configurado (`terraform init` sem `-backend=false`).

## Ordem na demo

O `infra-bootstrap` já está aplicado e não entra neste ciclo. O destroy daqui não toca no bucket de state.

Subida:

1. `infra-db` → **tf-apply**, em paralelo com `infra-k8s` → **tf-apply**.
2. Este repo → Actions → **tf-apply** (os tópicos existem antes das subscriptions).
3. **tf-apply** de cada serviço (subscription e dead-letter no repo do serviço).
4. Deploy dos serviços.

Descida:

1. **tf-destroy** de cada serviço (subscriptions saem primeiro; tópico com subscription não apaga).
2. Este repo → **tf-destroy**.
3. `infra-k8s` → **tf-destroy**.
4. `infra-db` → **tf-destroy**.

## Agentes

Ver [AGENTS.md](AGENTS.md).
