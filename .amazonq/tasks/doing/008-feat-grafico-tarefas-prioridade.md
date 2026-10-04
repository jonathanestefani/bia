# 008-feat-grafico-tarefas-prioridade

## Descrição

Criar uma tela dedicada de estatísticas que exiba um gráfico de barras mostrando o número de tarefas agrupadas por prioridade (Importante vs Normal), acessível através de um link na tela home.

Atualmente, a aplicação BIA possui tarefas com o campo booleano `importante`, que indica se uma tarefa é prioritária ou não. A proposta é criar uma visualização gráfica que permita ao usuário entender rapidamente a distribuição de tarefas por prioridade.

A solução envolve:
- Instalar e configurar shadcn/ui e suas dependências (Recharts para gráficos)
- Criar um novo endpoint no backend que retorne a contagem de tarefas agrupadas por prioridade
- Criar uma nova página `/estatisticas` com um gráfico de barras
- Adicionar um link na home que leve para a página de estatísticas
- Seguir o padrão visual do projeto

**Contexto técnico:**
- Frontend: React 18 com Vite
- Backend: Express + Sequelize
- Modelo de dados: `Tarefas` com campo `importante` (boolean)
- Padrão de rotas: ver `App.jsx` com rotas `/`, `/about`, `/versao`
- shadcn/ui: biblioteca de componentes React com Tailwind CSS
- Recharts: biblioteca de gráficos integrada ao shadcn/ui

## Estrutura de dados

### Modelo existente (Tarefas)
```javascript
{
  uuid: DataTypes.UUID,
  titulo: DataTypes.STRING,
  dia_atividade: DataTypes.STRING,
  importante: DataTypes.BOOLEAN  // true = Importante, false = Normal
}
```

### Endpoint esperado: `GET /api/tarefas/estatisticas`
```json
{
  "total": 10,
  "importante": 4,
  "normal": 6
}
```

## Critérios de aceitação

### Backend
- [ ] Existe um novo método `getEstatisticas` no controller `api/controllers/tarefas.js`
- [ ] O método retorna um objeto JSON com: `total`, `importante`, `normal`
- [ ] A contagem é feita usando Sequelize (ex: `count` com `where` para `importante: true` e `importante: false`)
- [ ] Existe uma nova rota `GET /api/tarefas/estatisticas` em `api/routes/tarefas.js`
- [ ] O endpoint responde corretamente mesmo quando não há tarefas cadastradas

### Frontend — shadcn/ui
- [ ] shadcn/ui está instalado e configurado no projeto (`npx shadcn@latest init`)
- [ ] Componente Chart do shadcn/ui está instalado (`npx shadcn@latest add chart`)
- [ ] Tailwind CSS está configurado corretamente (se necessário para shadcn/ui)
- [ ] Dependências Recharts instaladas

### Frontend — Página de Estatísticas
- [ ] Existe um novo componente `Estatisticas.jsx` em `client/src/components/`
- [ ] Existe uma nova rota `/estatisticas` registrada no `App.jsx`
- [ ] A página consome o endpoint `GET /api/tarefas/estatisticas` ao ser montada
- [ ] A página exibe um gráfico de barras com duas categorias: "Importante" e "Normal"
- [ ] O gráfico mostra a contagem de tarefas em cada categoria
- [ ] O gráfico usa o componente Chart do shadcn/ui (BarChart do Recharts)
- [ ] Quando não há tarefas, exibe mensagem informativa (ex: "Nenhuma tarefa cadastrada ainda")
- [ ] A página possui um link/botão para retornar à home (`/`)

### Frontend — Link na Home
- [ ] A tela home (`/`) possui um link ou botão que leva para `/estatisticas`
- [ ] O link está posicionado de forma visível (sugestão: próximo ao botão "Histórico de Versões" ou no Header)
- [ ] O link possui ícone descritivo (sugestão: `FaChartBar` do react-icons)

### Qualidade
- [ ] O gráfico é responsivo e se adapta a diferentes tamanhos de tela
- [ ] A página segue o padrão visual (CSS) das demais páginas do projeto
- [ ] O gráfico possui labels claros nos eixos X (categoria) e Y (quantidade)
- [ ] As cores do gráfico são consistentes com o tema da aplicação
- [ ] Logs de API são registrados (seguindo o padrão existente com `logApiRequest`, `logApiResponse`)

## Contexto técnico adicional

### Instalação shadcn/ui (Frontend)

```bash
cd client
npx shadcn@latest init
# Seguir prompts: 
# - Style: Default
# - Color: Slate
# - CSS variables: Yes

npx shadcn@latest add chart
```

### Exemplo de Query Sequelize (Backend)

```javascript
controller.getEstatisticas = async (req, res) => {
  try {
    const { Tarefas } = await initializeModels();
    
    const total = await Tarefas.count();
    const importante = await Tarefas.count({ where: { importante: true } });
    const normal = await Tarefas.count({ where: { importante: false } });
    
    res.send({ total, importante, normal });
  } catch (err) {
    res.status(500).send({
      message: err.message || "Erro ao buscar estatísticas.",
    });
  }
};
```

### Exemplo de Gráfico com shadcn/ui

```jsx
import { Bar, BarChart, XAxis, YAxis } from "recharts"
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart"

const chartData = [
  { categoria: "Importante", quantidade: 4 },
  { categoria: "Normal", quantidade: 6 },
]

const chartConfig = {
  quantidade: {
    label: "Tarefas",
    color: "#2563eb",
  },
}

<ChartContainer config={chartConfig}>
  <BarChart data={chartData}>
    <XAxis dataKey="categoria" />
    <YAxis />
    <ChartTooltip content={<ChartTooltipContent />} />
    <Bar dataKey="quantidade" fill="var(--color-quantidade)" radius={4} />
  </BarChart>
</ChartContainer>
```

## Estrutura esperada de arquivos

```
/bia
├── api/
│   ├── controllers/tarefas.js          # adicionar método getEstatisticas
│   └── routes/tarefas.js               # adicionar rota GET /api/tarefas/estatisticas
├── client/
│   ├── src/
│   │   ├── App.jsx                     # adicionar rota /estatisticas
│   │   ├── components/
│   │   │   ├── Estatisticas.jsx        # NOVO: página de estatísticas
│   │   │   └── Header.jsx ou Home      # adicionar link para /estatisticas
│   │   └── components/ui/              # NOVO: componentes shadcn/ui
│   │       └── chart.jsx               # componente Chart do shadcn
│   ├── components.json                 # NOVO: configuração shadcn/ui
│   └── tailwind.config.js              # pode precisar ser criado/ajustado
```

## Observações

- **Simplicidade primeiro:** usar gráfico de barras simples (2 categorias apenas)
- **shadcn/ui:** seguir a documentação oficial para instalação e uso de charts
- **Não quebrar o CSS existente:** garantir que a instalação do Tailwind (se necessário) não interfira nos estilos atuais
- **Compatibilidade:** testar que todas as páginas existentes continuam funcionando após adicionar shadcn/ui
- **Performance:** o endpoint de estatísticas deve ser leve (apenas counts, sem trazer todas as tarefas)

## Agente responsável

@dev

## Referências

- [shadcn/ui Charts](https://ui.shadcn.com/docs/components/chart)
- [Recharts Documentation](https://recharts.org/en-US/api)
- [Sequelize Count](https://sequelize.org/docs/v6/core-concepts/model-querying-basics/#-code-count-code-)
