# PRD — Internalizar CPF/CNPJ e suportar CNPJ Alfanumérico

**Status:** Pronto para implementação (decisões em aberto listadas na §14)
**Data:** 02/07/2026
**Stack alvo:** Ruby (gem `brazilian_document_wrapper`, compatível com Ruby >= 2.7.8)
**Prioridade:** Alta — o CNPJ alfanumérico já está em produção na Receita Federal desde
01/07/2026, e a gem hoje nem declara a dependência da qual depende para funcionar (§2).

---

## 1. Contexto e motivação

### 1.1 CNPJ alfanumérico entrou em produção

A Receita Federal começou a emitir, a partir de 01/07/2026, CNPJs alfanuméricos para
**novas inscrições** (rollout gradual, começando por grandes empresas; virada completa
até 01/01/2027). Os CNPJs numéricos existentes permanecem válidos e imutáveis — os dois
formatos vão coexistir indefinidamente. A partir de 06/07/2026 os ambientes de
autorização de documentos fiscais eletrônicos também passam a aceitar CNPJ alfanumérico
(NT Conjunta nº 2025.001), então o formato novo pode chegar via NF-e a qualquer momento.

Impacto direto: novos CNPJs de clientes, franqueados, sacados de boleto e emitentes de
NF-e podem conter letras nas 12 primeiras posições. Qualquer validação, parsing ou
armazenamento que assuma "CNPJ = 14 dígitos" passa a rejeitar — ou, pior, corromper
silenciosamente — documentos válidos.

### 1.2 A gem depende de uma gem que já não seria suficiente

Independente da urgência regulatória, a `brazilian_document_wrapper` deveria deixar de
depender de gems externas para a lógica de CPF/CNPJ: o objetivo é ser Ruby puro,
funcionando a partir do Ruby 2.7.8. Hoje ela delega inteiramente para
`brazilian_documents` (que por sua vez delega para `digit_checksum`) — e essa gem **não
suporta** CNPJ alfanumérico (a validação é via regex só de dígitos). Ou seja, mesmo sem
o objetivo de "gem pura", seríamos forçados a abandonar `brazilian_documents` para
suportar o novo formato. As duas frentes — internalizar a matemática e suportar o novo
formato — são a mesma mudança e devem sair no mesmo PR.

## 2. Estado atual da gem

A `Wrapper` (`lib/brazilian_document_wrapper/wrapper.rb`) delega toda a matemática para
`BRDocuments`:

| Método da wrapper | Delegação interna |
|---|---|
| `Wrapper#cpf?` / `#cnpj?` | `BRDocuments::CPF.valid?` / `CNPJ.valid?` |
| `Wrapper#pretty` / `#standard` | `BRDocuments::CPF.pretty` / `CNPJ.pretty` |
| `Wrapper#stripped` / `#to_param` | `BRDocuments::CPF.strip` / `CNPJ.strip` |
| `Wrapper#headquarter` | `BRDocuments::CNPJ.calculate_verify_digits` |
| `BrazilianDocumentWrapper.generate_cnpj/_cpf` | `BRDocuments::CNPJ.generate` / `CPF.generate` |

Dois problemas adicionais, independentes da falta de suporte a alfanumérico:

- O gemspec **não declara** `brazilian_documents` como dependência de runtime — a gem só
  funciona hoje porque o app host por acaso carrega `brazilian_documents` no bundle.
  Qualquer app que instale só esta gem quebra.
- `lib/brazilian_document_wrapper/version.rb` está em `0.1.0`, desalinhado com tags já
  publicadas (ex.: `0.1.5`).

## 3. Objetivo

Internalizar toda a regra de negócio de validação, cálculo de dígito verificador,
formatação e geração de CPF/CNPJ dentro da própria `brazilian_document_wrapper` —
cobrindo CNPJ numérico e alfanumérico —, eliminando a dependência de
`brazilian_documents`/`digit_checksum`, sem alterar a API pública já em uso (`Wrapper`
como subclasse de `String`, `String#to_brazilian_document`).

### Não-objetivos (fora deste PRD)

- Migração dos apps consumidores da gem (fica em cada repo consumidor; ver Anexo para um
  levantamento já feito em um deles).
- Alterações em layouts CNAB240/400 ou negociação de layout com bancos/TecnoSpeed.
- Migração de dados históricos (nenhum CNPJ existente muda).
- Alterações em pipelines Snowflake/dbt.
- Geração de inscrições reais (só a RFB atribui números — `generate_cnpj`/`generate_cpf`
  seguem sendo apenas para testes/factories).

## 4. Referências normativas

- Instrução Normativa RFB nº 2.229/2024 (institui o CNPJ alfanumérico).
- Manual de Cálculo do DV do CNPJ Alfanumérico (SERPRO/RFB):
  https://www.gov.br/receitafederal/pt-br/centrais-de-conteudo/publicacoes/documentos-tecnicos/cnpj
- Página oficial do projeto:
  https://www.gov.br/receitafederal/pt-br/acesso-a-informacao/acoes-e-programas/programas-e-atividades/cnpj-alfanumerico
- NT Conjunta nº 2025.001 (documentos fiscais eletrônicos, vigência em produção
  06/07/2026).

## 5. Especificação técnica

### 5.1 CPF (inalterado pela reforma — só numérico)

Módulo 11, 11 dígitos, dois DVs com pesos `10..2` e `11..2` da esquerda para a direita.
Sequências repetidas (`111.111.111-11`) são aritmeticamente válidas mas devem continuar
sendo rejeitadas, preservando o comportamento atual de `BRDocuments::CPF.valid?`.

### 5.2 CNPJ numérico (inalterado)

Módulo 11, pesos `5 4 3 2 9 8 7 6 5 4 3 2` (DV1) e `6 5 4 3 2 9 8 7 6 5 4 3 2` (DV2).
Sequências repetidas (`00.000.000/0000-00`) devem continuar sendo rejeitadas,
preservando o comportamento atual.

### 5.3 CNPJ alfanumérico (novo)

**Estrutura** (14 posições, tamanho inalterado):

| Posições | Conteúdo | Alfabeto |
|---|---|---|
| 1–8 | Raiz (identifica a entidade) | `0-9` e `A-Z` (maiúsculas) |
| 9–12 | Ordem do estabelecimento (matriz/filial) | `0-9` e `A-Z` (maiúsculas) |
| 13–14 | Dígitos verificadores (DV) | **somente** `0-9` |

- Máscara de exibição inalterada: `XX.XXX.XXX/XXXX-NN` (ex.: `12.ABC.345/01DE-35`).
- Letras minúsculas **não** fazem parte do formato canônico: normalizar para maiúsculas
  na entrada, nunca rejeitar por caixa.
- Um CNPJ 100% numérico continua sendo um CNPJ válido — é um caso particular do formato
  alfanumérico, e o algoritmo abaixo é retrocompatível com o cálculo legado (§5.2) quando
  a entrada é só dígitos.

**Algoritmo do DV** (módulo 11):

1. **Conversão de caracteres:** cada um dos 12 primeiros caracteres vira o valor
   `codepoint ASCII − 48`.
   - `'0'..'9'` → `0..9` (idêntico ao cálculo legado)
   - `'A'` → 17, `'B'` → 18, ..., `'Z'` → 42
2. **Pesos:** distribuídos de 2 a 9, **da direita para a esquerda**, reiniciando em 2
   após o 9. Fórmula: para o caractere na posição `i` contada a partir da direita
   (base 0), peso = `2 + (i % 8)`.
3. **DV1:** somar `valor × peso` de todas as posições; `r = soma % 11`. Se `r < 2`,
   `DV1 = 0`; senão `DV1 = 11 − r`.
4. **DV2:** anexar `DV1` ao final (13 caracteres) e repetir os passos 1–3.

> **Um único validador deve atender os dois formatos** — não criar dois caminhos de
> código para CNPJ numérico vs. alfanumérico; a conversão de caractere no passo 1 já
> garante retrocompatibilidade.

Implementação de referência (validada contra o exemplo oficial do manual SERPRO):

```ruby
def calc_dv(vals)
  sum = vals.reverse.each_with_index.sum { |v, i| v * (2 + i % 8) }
  r = sum % 11
  r < 2 ? 0 : 11 - r
end
```

### 5.4 Zero-fill de dígitos perdidos (comportamento existente, preservar com ressalva)

`Wrapper#value` hoje aplica `rjust(14, '0')`/`rjust(11, '0')` para recuperar CPFs/CNPJs
numéricos que perderam zeros à esquerda (efeito colateral clássico de colunas de banco
tipadas como inteiro). Esse comportamento deve ser **preservado** — os testes atuais
dependem dele — mas ele só faz sentido para entradas puramente numéricas: uma raiz
alfanumérica nunca teria passado por uma coluna `integer` para começo de conversa, então
o zero-fill não deve ser estendido a entradas com letras.

## 6. Requisitos funcionais

### RF1 — Internalizar validação, DV, strip, formatação e geração

Sem nenhuma dependência de runtime além de Rails, reimplementando dentro da gem o que
hoje vem de `BRDocuments`/`digit_checksum`:

- `stripped`/`to_param` — remover máscara. Para CNPJ, preservar letras (normalizadas
  para maiúsculas); para CPF, comportamento atual (só dígitos) não muda.
- `pretty`/`standard` — máscaras `%s.%s.%s/%s-%s` (CNPJ, grupos 2-3-3-4-2) e
  `%s.%s.%s-%s` (CPF, grupos 3-3-3-2), a partir da forma normalizada.
- `cpf?`/`cnpj?` — `cnpj?` passa a aceitar `\A[0-9A-Z]{12}\d{2}\z` (após strip) mais
  conferência dos dois DVs; `cpf?` mantém a regra atual. Nunca levantam exceção, mesmo
  para `nil`/string vazia/tipos inesperados.
- `BrazilianDocumentWrapper.generate_cnpj`/`.generate_cpf` — mantêm a assinatura atual
  (`generate_cnpj(formatted = true)`), sempre gerando DVs corretos e não repetidos;
  `generate_cnpj` continua gerando apenas numérico por padrão (compatibilidade com
  factories já existentes nos apps consumidores).

### RF2 — `Wrapper#branch(code)`

Generalizar `headquarter` para qualquer filial:

```ruby
'12.345.678/0001-95'.to_brazilian_document.branch('0003')
# => '12.345.678/0003-XX' (DVs recalculados)
```

`headquarter` passa a ser `branch('0001')` internamente, sem mudar sua API pública.

### RF3 — Contrato de erro fail-fast (inalterado, só reafirmado)

`pretty`, `standard`, `stripped`, `to_param`, `headquarter` e `branch` continuam
levantando exceção para documento inválido. Quem precisa tratar documento inválido como
fluxo normal deve guardar com `invalid_document?`/`invalid_cnpj?` antes de chamar esses
métodos — **sem** variantes lenientes (`pretty_or_nil` etc.) na gem. Documentar essa
regra no README.

### RF4 — Namespace da exceção

Mover `InvalidDocumentError` (hoje top-level, poluindo o namespace global) para
`BrazilianDocumentWrapper::InvalidDocumentError`, mantendo alias top-level deprecado por
uma versão. Motivação concreta: pelo menos um app consumidor tem
`rescue BRDocuments::InvalidDocumentError` — constante que **não existe** em
`BRDocuments` (código morto, só não estourou `NameError` porque as specs fazem
`stub_const`). A exceção certa a capturar sempre foi a top-level da wrapper, e o
namespace correto deixa isso inequívoco.

## 7. Requisitos não funcionais

- Zero dependências de runtime novas (Ruby puro).
- Validação O(1)/O(n) trivial — sem I/O, sem chamadas externas.
- Cobertura de testes de 100% no código novo.
- Logs/erros não devem truncar nem reformatar CNPJs (evitar interpolações que apliquem
  `to_i`).

## 8. Higiene do gemspec e versionamento

- Declarar corretamente que a gem não tem dependências de runtime além de `rails`
  (remover qualquer suposição implícita de `brazilian_documents`).
- Corrigir `version.rb`, hoje em `0.1.0` e desalinhado com tags já publicadas.
- Corrigir metadado `allowed_push_host` (hoje um `TODO` no gemspec).
- Nova versão: **0.2.0**.

## 9. Casos de teste obrigatórios

**Vetores de CNPJ alfanumérico**, verificados contra o algoritmo do manual oficial
SERPRO:

| Base (12 chars) | DVs esperados | CNPJ completo | Observação |
|---|---|---|---|
| `12ABC34501DE` | `35` | `12.ABC.345/01DE-35` | Exemplo oficial do manual SERPRO |
| `112223330001` | `81` | `11.222.333/0001-81` | Numérico legado clássico |
| `000000000001` | `91` | `00.000.000/0001-91` | Numérico com zeros à esquerda |
| `607011900001` | `04` | `60.701.190/0001-04` | Numérico real (Itaú) — DV com zero |
| `JWC9NAYX0KV1` | `08` | — | Caso de borda: resto < 2 → DV1 = 0 |
| `CYS8RBHTF4SZ` | `09` | — | Caso de borda: resto < 2 → DV1 = 0 |
| `CASHU0000001` | `90` | — | Alfanumérico com ordem numérica |
| `A1B2C3D4E5F6` | `68` | — | Alternância letra/dígito |

**Casos negativos e de normalização:**

- `12.ABC.345/01DE-36` → inválido (DV errado por 1).
- `12.abc.345/01de-35` → **válido** após normalização (uppercase).
- `12ABC34501D` (13 chars) e 15 chars → inválidos.
- DV com letra: `12ABC34501DEA5` → inválido (posições 13–14 devem ser dígitos).
- Caracteres fora do alfabeto: `12ÁBC34501DE35`, `12-AB*34501DE35` → inválidos (acentos
  e símbolos não são removíveis como máscara).
- `nil`, `""`, `"   "`, tipos inesperados → `cpf?`/`cnpj?` retornam `false` sem exceção.

**CPF e CNPJ numérico:**

- Válidos e inválidos (DV errado, tamanho errado, vazio).
- Sequências repetidas (`000.000.000-00`, `00.000.000/0000-00`) → inválidos.
- Zeros à esquerda: strings com 10/13 caracteres válidas após o zero-fill do
  `Wrapper#value` (§5.4) — só para entradas puramente numéricas.
- Formatos mistos aceitos no parse: `99.999.999/9999-99`, `99-999-999/9999-99`,
  `99999999/999999`, `99999999999999`.

**API e round-trip:**

- `branch('0001')` produz o mesmo resultado que `headquarter`; `branch` com código
  arbitrário recalcula os DVs.
- `generate_cnpj`/`generate_cpf`: formatado por padrão, sempre válido, nunca repetido.
- Round-trip: `generate → stripped → pretty → cnpj?`/`cpf?` estável.
- Regressão: rodar o validador novo contra uma amostra de CPFs/CNPJs numéricos reais já
  em uso — 100% devem continuar válidos.

**Casos derivados do uso real em app consumidor** (evidência completa no Anexo):

- `branch('0003')` reproduz o cálculo hoje feito manualmente em
  `spec/models/invoice_group_spec.rb:17` (CNPJ de filial `0003`), sem que o app precise
  chamar `calculate_verify_digits` diretamente.
- Cobertura de todos os padrões de chamada já em uso num app consumidor real:
  `generate_cnpj`/`generate_cpf` (86 call sites combinados), `pretty` (25),
  `stripped` (7), `cnpj?`/`cpf?` (7), `invalid_cnpj?` (2).
- Dispatch automático: `pretty`/`cnpj?`/`cpf?` chamados tanto num documento numérico
  quanto num alfanumérico escolhem o tipo certo sem que o caller informe qual é (hoje o
  app escolhe manualmente `CNPJ.x` vs `CPF.x`; a wrapper decide sozinha por validade e
  comprimento).
- `rescue BrazilianDocumentWrapper::InvalidDocumentError` captura corretamente o erro
  levantado por `pretty`/`standard`/`stripped`/`to_param`/`headquarter`/`branch` — cobre
  a correção do rescue fantasma (`BRDocuments::InvalidDocumentError`, que nunca existiu)
  encontrado no app consumidor.

## 10. Critérios de aceite

1. `cpf?`/`cnpj?` aceitam CPF, CNPJ numérico e CNPJ alfanumérico, passando em todos os
   vetores da §9.
2. Gemspec não referencia mais `brazilian_documents`/`digit_checksum`, direta ou
   indiretamente.
3. `Wrapper#branch(code)` implementado; `headquarter` é `branch('0001')`.
4. `BrazilianDocumentWrapper::InvalidDocumentError` é a exceção pública, com alias
   top-level deprecado.
5. API pública (`Wrapper < String`, `String#to_brazilian_document`, contrato fail-fast)
   inalterada para quem já consome a gem.
6. Suíte de testes verde, incluindo os testes de regressão da §9.

## 11. Checklist de auditoria para apps consumidores

Esta gem não consegue auditar sozinha os apps que a consomem, mas deve publicar este
checklist (README ou CHANGELOG da 0.2.0) para quem for migrar:

- **Banco de dados:** colunas que guardam CPF/CNPJ devem ser `string`/`varchar`/
  `citext`, nunca `bigint`/`integer`/`numeric`. Índices únicos precisam de normalização
  consistente (sem máscara, uppercase) — senão duplicatas lógicas passam despercebidas.
- **Validações ad-hoc:** buscar regexes `\d{14}`/`\d{11}`, chamadas `to_i`/
  `Integer(cnpj)` e, especialmente, `gsub(/\D/, "")` — substituir tudo pelos métodos da
  wrapper (ver risco abaixo).
- **Integrações externas:** pontos onde CPF/CNPJ é enviado/recebido de APIs de
  parceiros — mapear onde o contrato do parceiro ainda declara o campo como numérico
  (não dá para corrigir do lado da gem).
- **Arquivos posicionais (CNAB):** campos `picture 9` de CNPJ não suportam letras;
  mudança de layout depende de especificação FEBRABAN/banco, fora do controle desta gem.
- **Analytics:** queries/modelos dbt ou BI que fazem cast de CNPJ para numérico ou
  `lpad`/`to_number` quebram silenciosamente com CNPJ alfanumérico.

Um app consumidor já rodou esse levantamento de forma concreta — ver Anexo.

## 12. Riscos e observações

- **Sanitização destrutiva:** `gsub(/\D/, "")`, muito comum em código de apps
  consumidores, **apaga as letras** de um CNPJ alfanumérico silenciosamente —
  `12ABC34501DE35` vira `12345013`, uma string de tamanho e valor errados, sem erro
  nenhum. É o motivo principal do checklist da §11.
- **Coexistência longa:** os dois formatos de CNPJ vão coexistir para sempre; não tratar
  o alfanumérico como "modo de transição" em nenhum lugar do código.
- **Exceção fantasma:** o bug encontrado (`BRDocuments::InvalidDocumentError`
  inexistente, mascarado por `stub_const` nas specs de um app consumidor) é evidência de
  que testes que fazem stub de constantes externas escondem regressões — vale revisar se
  há padrão parecido em outros lugares.
- **Parceiros:** a capacidade de bancos, ERPs e integrações CNAB de aceitar CNPJ
  alfanumérico é externa a este PRD; o checklist da §11 existe para mapear onde isso
  importa, não para resolver.

## 13. Plano de entrega

1. **Este repo:** implementar §5–§8, subir para `0.2.0`.
2. **Apps consumidores:** cada um migra em seu próprio repo/PR, usando o checklist da
   §11 e a nova API. Fora do escopo deste PRD (ver Anexo para um exemplo já detalhado).

## 14. Decisões em aberto

- [ ] `generate_cnpj` ganha flag `alphanumeric: true` para gerar CNPJ com letras?
  (recomendação: sim, default `false`, para não quebrar factories existentes).
- [ ] Vale expor `Wrapper#root`/`#order` (raiz de 8 e ordem de 4 posições isoladas)? Hoje
  `stripped_prefix`/`pretty_prefix` já cobrem a raiz; nenhum call site conhecido precisa
  da ordem isolada — avaliar só se surgir necessidade real.
- [ ] Validator dedicado no estilo ActiveModel (`validates :cnpj, cnpj: true`)? Não
  incorporado por ora: a integração via `acts_as_brazilian_document` +
  `BrazilianDocumentType` já cobre validação em nível de model. Reavaliar se algum app
  pedir validação fora desse fluxo.

---

## Anexo — Contexto de um app consumidor

Levantamento feito no repo de um dos apps que consome esta gem, útil como evidência
concreta do impacto real das decisões acima. Os padrões de uso mapeados aqui já viraram
requisitos de teste formais na §9 ("Casos derivados do uso real em app consumidor");
o restante deste Anexo fica como referência — a migração em si é responsabilidade
daquele repo, não deste PRD.

### Inventário de usos diretos de `BRDocuments`

Prefixo `BRDocuments::` omitido na coluna "Uso atual" abaixo, por brevidade.

| Uso atual | Ocorrências | Destino após migração |
|---|---|---|
| `CNPJ.generate` | 76 (factories, specs, thor) | `BrazilianDocumentWrapper.generate_cnpj` |
| `CNPJ.pretty(x)` | 23 | `x.to_brazilian_document.pretty` |
| `CPF.generate` | 10 | `BrazilianDocumentWrapper.generate_cpf` |
| `CNPJ.strip(x)` | 7 | `x.to_brazilian_document.stripped` |
| `CNPJ.valid?(x)` | 4 | `x.to_brazilian_document.cnpj?` |
| `CPF.valid?(x)` | 3 | `x.to_brazilian_document.cpf?` |
| `CPF.pretty(x)` | 2 | `x.to_brazilian_document.pretty` |
| `CNPJ.invalid?(x)` | 2 | `x.to_brazilian_document.invalid_cnpj?` |
| `IE.available_states` | 2 | constante local no app (fora do escopo da gem) |
| `CNPJ.calculate_verify_digits` | 1 spec | `Wrapper#branch(code)` (§6, RF2) |
| `rescue BRDocuments::InvalidDocumentError` | 2 services | ver RF4 (§6) |

### Pontos que exigem auditoria manual (mudança de comportamento)

`pretty` na wrapper **levanta exceção** para documento inválido; `BRDocuments` formatava
sem validar. Nesse app, os pontos que formatam dados externos possivelmente sujos e
precisam de guarda com `invalid_document?` são: `app/services/invitation_list_parser.rb`
(CSV de usuário), `app/services/invitation_data_from_invoice.rb` e
`app/services/xml/invoice_parser.rb` (XML NFe),
`app/services/invoice_dependants_savior.rb` (XML),
`app/jobs/sped_file_registration_job.rb` (arquivo SPED), e os jobs de checagem de
inconsistência de fatura em `buy_now_pay_later/` e `invoice_audit/` (XML).

### Decisões de design validadas por esse levantamento

- **Dispatch automático CPF/CNPJ:** os call sites hoje escolhem explicitamente
  `CNPJ.pretty` vs `CPF.pretty`; a wrapper decide sozinha por validade + comprimento.
  Decisão: aceitar o dispatch automático, confiando nas validações de modelo
  existentes — não criar variantes explícitas (`pretty_cnpj!`).
- **`BRDocuments::IE.available_states`** (lista de UFs) não é regra de documento
  fiscal — não entra no escopo desta gem; cada app resolve com uma constante local.

### Plano de migração desse app (referência, não bloqueia este PRD)

1. Trocar mecanicamente todos os usos da tabela acima pela API da wrapper.
2. Auditar os pontos de dados externos listados acima, guardando com
   `invalid_document?` onde inválido for fluxo esperado.
3. Corrigir os dois rescues fantasma: trocar `BRDocuments::InvalidDocumentError` por
   `BrazilianDocumentWrapper::InvalidDocumentError` e remover os `stub_const` das specs
   correspondentes.
4. Remover `gem 'brazilian_documents'` do Gemfile, confirmar que `brazilian_documents` e
   `digit_checksum` saíram do lockfile, bump da wrapper para `0.2.0`.
5. Suíte completa verde + lint com autocorreção.

Recomendação: um PR único, não fatiado — a mudança é mecânica, e fatiar deixaria duas
fontes de verdade (`BRDocuments` e a wrapper) convivendo por mais tempo que o
necessário.
