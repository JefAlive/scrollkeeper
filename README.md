# Scrollkeeper

O Scrollkeeper é um ambiente de pesquisa de IA local e isolado de forma portátil. Ele utiliza o Bubblewrap para colocar em sandbox um fluxo de trabalho multi-agente (Planner e Researcher) alimentado pelo Hermes, sincronizando tarefas e relatórios diretamente em um cofre Markdown compatível com o Obsidian.

## Motivação

- Hermes pode ser bem comportado, mas não garante isolamento;
- Docker é uma alternativa pesada pra isolamento pra quem já está com a máquina em sobrecarga (cenário comum pra quem roda IA local);

## Estrutura

```
Vault Obsidian
│
├── [outros diretórios e notas do Obsidian aqui...]
|
└── Scrollkeeper/                 📦 Este repositório git
    │
    ├── Architecture.md           🧠 Visão técnica do sistema
    ├── Decisions.md              📌 Decisões arquiteturais
    ├── Roadmap.md                🗺️ Planejamento macro
    │
    │   ╭ observação ────────────────────────────────────╮
    |   |                                                |
    │   │ esses 3 itens acima podem não faer             │
    │   │ muito sentido especificamente pro Scrollkeeper,│
    │   │ mas estou criando esta estrutura porque irei   │
    │   │ utilizá-la também em projetos de código        │
    |   |                                                |
    │   ╰────────────────────────────────────────────────╯
    │
    ├── hermes/
    │   │
    │   ├── profiles/              🎭 Comportamento dos agentes
    │   │   ├── planner/SOUL.md    🧭 Define tarefas e estrutura trabalho
    │   │   └── researcher/SOUL.md 🔍 Executa a pesquisa e faz um relatório
    │   │
    │   ├── epics/                 🎯 Objetivos grandes do projeto/pesquisa
    │   │
    │   ├── tasks/                 🧩 Trabalho granular executável
    │   │
    │   └── memory/
    │       └── context.md         🧠 Snapshot leve do estado atual do projeto
    │
    ├── infra/
    │   │
    │   ├── .hermes/               🤖 Diretório criado automaticamente pelo Hermes
    │   |
    │   └── bubblewrap/            🔐 Isolamento real de execução (sandbox)
    │       │
    │       │
    │       ├── planner.sh         🧭 Hermes planner
    │       ├── researcher.sh      🔍 Hermes researcher
    │       │
    │       └── env/
    │           ├── planner.env    ⚙️ Config de ambiente do planner
    │           ├── coder.env      ⚙️ Config de ambiente do coder
    │           └── reviewer.env   ⚙️ Config de ambiente do reviewer
    │
    └── research/                  📄 Relatórios das pesquisas realizadas
```