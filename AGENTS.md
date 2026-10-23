# Tech Challenge — Guia para agentes (`infra-events`)

Terraform dos **tópicos Pub/Sub** usados pelos serviços da oficina na GCP. Org [fiap-vcosta](https://github.com/fiap-vcosta).

## Antes de mudar código

1. Ler ADRs em [`docs/adrs/`](docs/adrs/) quando existirem
2. Não inventar layout paralelo ao root module em `terraform/`
3. Não rodar `apply`/`destroy` sem confirmação explícita do usuário
4. **Git:** nunca commit/push direto em `main` — branch → PR → merge (ver [`.cursor/rules/git-workflow.mdc`](.cursor/rules/git-workflow.mdc))

## Responsabilidade

| Peça | Papel |
|------|--------|
| Terraform | Tópicos Pub/Sub do ciclo de demo |
| State | Backend remoto |
| Fora de escopo | Cloud SQL, GKE, subscriptions (ficam nos repositórios dos serviços), código de aplicação |

## Regras canônicas (resumo)

- Apply/destroy manuais (`tf-apply` / `tf-destroy`)
- Só tópicos; subscriptions não se criam aqui
- Sem secrets no Git

## Comandos

```bash
cd terraform
terraform fmt -check
terraform init -backend=false
terraform validate
# plan/apply: só com backend configurado e confirmação humana
```
