defmodule Dominio.Participante do
  @moduledoc """
  Representa a un participante de la Hackathon.
  Puede ser un estudiante regular o un mentor.
  """

  # Estructura de datos del participante
  defstruct [
    :id,
    :nombre,
    :correo,
    :rol,           # :participante o :mentor
    :equipo,        # Nombre del equipo al que pertenece
    :habilidades,   # Lista de habilidades técnicas
    :fecha_registro
  ]

  @doc """
  Crea un nuevo participante
  """
  def nuevo(nombre, correo, rol \\ :participante) do
    %__MODULE__{
      id: generar_id(),
      nombre: nombre,
      correo: correo,
      rol: rol,
      equipo: nil,
      habilidades: [],
      fecha_registro: DateTime.utc_now()
    }
  end

  @doc """
  Asigna un equipo al participante
  """
  def asignar_equipo(participante, nombre_equipo) do
    %{participante | equipo: nombre_equipo}
  end

  @doc """
  Desasigna el equipo del participante
  """
  def desasignar_equipo(participante) do
    %{participante | equipo: nil}
  end

  @doc """
  Agrega una habilidad al participante
  """
  def agregar_habilidad(participante, habilidad) do
    if habilidad in participante.habilidades do
      {:error, "Ya tienes esta habilidad registrada"}
    else
      habilidades_actualizadas = [habilidad | participante.habilidades]
      {:ok, %{participante | habilidades: habilidades_actualizadas}}
    end
  end

  @doc """
  Verifica si el participante es mentor
  """
  def es_mentor?(participante) do
    participante.rol == :mentor
  end

  @doc """
  Verifica si el participante tiene equipo
  """
  def tiene_equipo?(participante) do
    participante.equipo != nil
  end

  # Función privada para generar ID único
  defp generar_id() do
    :crypto.strong_rand_bytes(6)
    |> Base.encode16()
    |> String.downcase()
  end
end
