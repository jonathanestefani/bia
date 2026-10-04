import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { FaChartBar, FaArrowLeft } from "react-icons/fa";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from "recharts";

const apiUrl = import.meta.env.VITE_API_URL || "";

const CORES = {
  importante: "#ef4444",
  normal: "#3b82f6",
};

const Estatisticas = () => {
  const [estatisticas, setEstatisticas] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchEstatisticas();
  }, []);

  const fetchEstatisticas = async () => {
    try {
      setLoading(true);
      setError(null);
      const res = await fetch(`${apiUrl}/api/tarefas/estatisticas`);
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      }
      const data = await res.json();
      setEstatisticas(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const chartData = estatisticas
    ? [
        { categoria: "Importante", quantidade: estatisticas.importante },
        { categoria: "Normal", quantidade: estatisticas.normal },
      ]
    : [];

  const temTarefas = estatisticas && estatisticas.total > 0;

  return (
    <div className="estatisticas-page">
      <div className="estatisticas-header">
        <FaChartBar className="estatisticas-icon" />
        <div>
          <h2>Estatísticas</h2>
          <p className="estatisticas-subtitle">Distribuição de tarefas por prioridade</p>
        </div>
      </div>

      {loading && (
        <div className="estatisticas-estado">
          <p className="estatisticas-loading">Carregando estatísticas...</p>
        </div>
      )}

      {!loading && error && (
        <div className="estatisticas-estado estatisticas-erro">
          <p>Erro ao carregar: {error}</p>
          <button className="btn" onClick={fetchEstatisticas}>
            Tentar novamente
          </button>
        </div>
      )}

      {!loading && !error && !temTarefas && (
        <div className="estatisticas-estado">
          <p className="estatisticas-vazio">Nenhuma tarefa cadastrada ainda</p>
          <p className="estatisticas-vazio-sub">
            Adicione tarefas na tela inicial para ver as estatísticas aqui.
          </p>
        </div>
      )}

      {!loading && !error && temTarefas && (
        <>
          <div className="estatisticas-cards">
            <div className="estatisticas-card">
              <span className="estatisticas-card-numero">{estatisticas.total}</span>
              <span className="estatisticas-card-label">Total</span>
            </div>
            <div className="estatisticas-card estatisticas-card-importante">
              <span className="estatisticas-card-numero">{estatisticas.importante}</span>
              <span className="estatisticas-card-label">Importantes</span>
            </div>
            <div className="estatisticas-card estatisticas-card-normal">
              <span className="estatisticas-card-numero">{estatisticas.normal}</span>
              <span className="estatisticas-card-label">Normais</span>
            </div>
          </div>

          <div className="estatisticas-grafico">
            <ResponsiveContainer width="100%" height={220}>
              <BarChart
                data={chartData}
                margin={{ top: 16, right: 16, left: 0, bottom: 8 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border-color)" />
                <XAxis
                  dataKey="categoria"
                  tick={{ fontSize: 13, fill: "var(--text-secondary)" }}
                  axisLine={{ stroke: "var(--border-color)" }}
                  tickLine={false}
                />
                <YAxis
                  allowDecimals={false}
                  tick={{ fontSize: 12, fill: "var(--text-secondary)" }}
                  axisLine={false}
                  tickLine={false}
                />
                <Tooltip
                  contentStyle={{
                    background: "var(--bg-card)",
                    border: "1px solid var(--border-color)",
                    borderRadius: "6px",
                    fontSize: "0.875rem",
                    color: "var(--text-primary)",
                  }}
                  cursor={{ fill: "var(--bg-secondary)" }}
                  formatter={(value) => [value, "Tarefas"]}
                />
                <Bar dataKey="quantidade" radius={[4, 4, 0, 0]} maxBarSize={80}>
                  {chartData.map((entry) => (
                    <Cell
                      key={entry.categoria}
                      fill={
                        entry.categoria === "Importante"
                          ? CORES.importante
                          : CORES.normal
                      }
                    />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </>
      )}

      <div className="estatisticas-footer">
        <Link to="/" className="back-button">
          <FaArrowLeft /> Voltar
        </Link>
      </div>
    </div>
  );
};

export default Estatisticas;
