defmodule Dominio.Equipo do
  @moduledoc """
  Representa un equipo participante en la Hackathon.
  Los equipos pueden tener múltiples miembros y trabajan en un proyecto.
  """

  defstruct [
    :id,
    :nombre,
    :tema,          # Categoría del proyecto (Educación, Ambiental, Social)
    :miembros,      # Lista de nombres de participantes
    :lider,         # Nombre del líder del equipo
    :estado,        # :activo, :inactivo
    :fecha_creacion
  ]

  @doc """
  Crea un nuevo equipo
  """
  def nuevo(nombre, tema, lider) do
    %__MODULE__{
      id: generar_id(),
      nombre: nombre,
      tema: tema,
      miembros: [lider],
      lider: lider,
      estado: :activo,
      fecha_creacion: DateTime.utc_now()
    }
  end

  @doc """
  Agrega un miembro al equipo
  """
  def agregar_miembro(equipo, nombre_miembro) do
    # Verificar que el miembro no esté ya en el equipo
    if nombre_miembro in equipo.miembros do
      {:error, "Este participante ya está en el equipo"}
    else
      miembros_actualizados = [nombre_miembro | equipo.miembros]
      {:ok, %{equipo | miembros: miembros_actualizados}}
    end
  end

  @doc """
  Elimina un miembro del equipo
  """
  def remover_miembro(equipo, nombre_miembro) do
    if nombre_miembro == equipo.lider do
      {:error, "No se puede remover al líder del equipo"}
    else
      miembros_actualizados = List.delete(equipo.miembros, nombre_miembro)
      {:ok, %{equipo | miembros: miembros_actualizados}}
    end
  end

  @doc """
  Lista todos los miembros del equipo
  """
  def listar_miembros(equipo) do
    equipo.miembros
  end

  @doc """
  Cuenta la cantidad de miembros
  """
  def contar_miembros(equipo) do
    length(equipo.miembros)
  end

  @doc """
  Cambia el estado del equipo
  """
  def cambiar_estado(equipo, nuevo_estado) do
    %{equipo | estado: nuevo_estado}
  end

  # Genera un ID único para el equipo
  defp generar_id() do
    :crypto.strong_rand_bytes(6)
    |> Base.encode16()
    |> String.downcase()
  end
end
