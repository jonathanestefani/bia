# 007-feat-date-picker-calendario

## Descrição

Substituir o campo de texto livre "Data/Prazo" por um calendário interativo (date picker) no formulário de adição de tarefas na tela home da aplicação BIA.

Atualmente, o campo "Data/Prazo" é um `input type="text"` que aceita entrada livre do usuário. A proposta é substituí-lo por um `input type="date"` nativo do HTML5, oferecendo uma interface de calendário visual e garantindo formato de data consistente.

**Importante:** O campo `dia_atividade` no banco de dados é do tipo `STRING`, portanto a conversão de formato deve ser feita no frontend antes do envio. O padrão atual usado é `DD/MM/YYYY` (formato pt-BR via `toLocaleDateString('pt-BR')`).

A solução deve:
- Manter o mesmo comportamento: se o usuário não selecionar data, usar a data atual
- Converter o valor do date picker (formato `YYYY-MM-DD`) para o formato brasileiro `DD/MM/YYYY` antes de enviar ao backend
- Garantir retrocompatibilidade com os dados existentes no banco
- Seguir o padrão visual dos demais campos do formulário

**Contexto técnico:**
- Componente a modificar: `client/src/components/AddTask.jsx`
- Campo atual: `input type="text"` com placeholder "Quando?"
- Estado React: `const [dia, setDia] = useState("")`
- Formato esperado pelo backend: string no padrão brasileiro `DD/MM/YYYY`
- Formato do date picker: `YYYY-MM-DD` (padrão HTML5)
- Conversão necessária: date picker → formato pt-BR antes de `onAdd()`

## Critérios de aceitação

- [x] O campo "Data/Prazo" no formulário é renderizado como `<input type="date" />`
- [x] O date picker exibe um calendário visual ao ser clicado (comportamento nativo do navegador)
- [x] Quando o usuário seleciona uma data no calendário, o valor é armazenado no estado `dia`
- [x] Quando o usuário submete o formulário SEM selecionar data, o sistema usa a data atual no formato `DD/MM/YYYY` (comportamento existente mantido)
- [x] Quando o usuário submete o formulário COM data selecionada, o valor é convertido de `YYYY-MM-DD` para `DD/MM/YYYY` antes de chamar `onAdd()`
- [x] O backend recebe `dia_atividade` como string no formato `DD/MM/YYYY` (sem quebrar compatibilidade)
- [x] O campo mantém o estilo visual consistente com os demais campos do formulário (classe `form-control`)
- [x] A funcionalidade de criar tarefas continua funcionando corretamente
- [x] Tarefas criadas com o date picker são exibidas corretamente na lista de tarefas
- [x] Tarefas existentes no banco continuam sendo exibidas sem problemas

## Contexto técnico adicional

### Conversão de formato necessária

```javascript
// Entrada do date picker: "2026-01-26" (YYYY-MM-DD)
// Saída esperada: "26/01/2026" (DD/MM/YYYY)

// Exemplo de conversão:
const converterData = (dataISO) => {
  if (!dataISO) return new Date().toLocaleDateString('pt-BR');
  const [ano, mes, dia] = dataISO.split('-');
  return `${dia}/${mes}/${ano}`;
};
```

### Comportamento esperado no `onSubmit`

```javascript
onAdd({ 
  titulo: titulo.trim(), 
  dia_atividade: converterData(dia), // converter aqui
  importante 
});
```

## Agente responsável

@dev

## Observações

- Não é necessário alterar o modelo, migration ou controller — o backend já trata `dia_atividade` como string
- Não é necessário adicionar bibliotecas externas (react-datepicker, etc.) — usar `input type="date"` nativo
- O date picker nativo funciona em todos os navegadores modernos e mobile
- A UX melhora significativamente: interface visual de calendário + validação automática de formato
