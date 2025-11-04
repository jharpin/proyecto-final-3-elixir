defmodule Dominio.Mentor do
  @moduledoc """
  Representa a un mentor que asesora a los equipos durante la Hackathon.
  Los mentores tienen especialidades y pueden dar retroalimentación.
  """

  defstruct [
    :id,
    :nombre,
    :correo,
    :especialidad,      # Área de expertise
    :disponible,        # true/false
    :equipos_asignados, # Lista de nombres de equipos
    :fecha_registro
  ]

  @doc """
  Crea un nuevo mentor
  """
  def nuevo(nombre, correo, especialidad) do
    %__MODULE__{
      id: generar_id(),
      nombre: nombre,
      correo: correo,
      especialidad: especialidad,
      disponible: true,
      equipos_asignados: [],
      fecha_registro: DateTime.utc_now()
    }
  end

  @doc """
  Asigna un equipo al mentor
  """
  def asignar_equipo(mentor, nombre_equipo) do
    if nombre_equipo in mentor.equipos_asignados do
      {:error, "Este equipo ya está asignado"}
    else
      equipos_actualizados = [nombre_equipo | mentor.equipos_asignados]
      {:ok, %{mentor | equipos_asignados: equipos_actualizados}}
    end
  end

  @doc """
  Remueve un equipo del mentor
  """
  def remover_equipo(mentor, nombre_equipo) do
    equipos_actualizados = List.delete(mentor.equipos_asignados, nombre_equipo)
    %{mentor | equipos_asignados: equipos_actualizados}
  end

  @doc """
  Cambia la disponibilidad del mentor
  """
  def cambiar_disponibilidad(mentor, disponible) do
    %{mentor | disponible: disponible}
  end

  @doc """
  Verifica si el mentor tiene un equipo asignado
  """
  def tiene_equipo?(mentor, nombre_equipo) do
    nombre_equipo in mentor.equipos_asignados
  end

  @doc """
  Cuenta cuántos equipos tiene asignados
  """
  def contar_equipos(mentor) do
    length(mentor.equipos_asignados)
  end

  # Genera ID único
  defp generar_id() do
    :crypto.strong_rand_bytes(6)
    |> Base.encode16()
    |> String.downcase()
  end
end
