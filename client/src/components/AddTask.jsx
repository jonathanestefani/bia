import React, { useState } from "react";
import Modal from "./Modal";

const converterData = (dataISO) => {
  if (!dataISO) return new Date().toLocaleDateString('pt-BR');
  const [ano, mes, dia] = dataISO.split('-');
  return `${dia}/${mes}/${ano}`;
};

const AddTask = ({ onAdd }) => {
  const [titulo, setTitulo] = useState("");
  const [dia, setDia] = useState("");
  const [importante, setImportante] = useState(false);
  const [showModal, setShowModal] = useState(false);

  const onSubmit = (e) => {
    e.preventDefault();

    if (!titulo.trim()) {
      setShowModal(true);
      return;
    }

    onAdd({ 
      titulo: titulo.trim(), 
      dia_atividade: converterData(dia), 
      importante 
    });

    setTitulo("");
    setDia("");
    setImportante(false);
  };

  return (
    <form className="add-form" onSubmit={onSubmit}>
      <div className="form-control">
        <label>Tarefa</label>
        <input
          type="text"
          placeholder="O que você precisa fazer?"
          value={titulo}
          onChange={(e) => setTitulo(e.target.value)}
        />
      </div>
      
      <div className="form-control">
        <label>Data/Prazo</label>
        <input
          type="date"
          value={dia}
          onChange={(e) => setDia(e.target.value)}
        />
      </div>
      
      <div className="form-control-check">
        <input
          type="checkbox"
          id="importante"
          checked={importante}
          onChange={(e) => setImportante(e.target.checked)}
        />
        <label htmlFor="importante">Importante</label>
      </div>
      
      <button type="submit" className="btn btn-block success">
        Add Task
      </button>
      
      <Modal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        title="Campo obrigatório"
        message="Por favor, adicione uma descrição para a tarefa"
        type="warning"
      />
    </form>
  );
};

export default AddTask;
