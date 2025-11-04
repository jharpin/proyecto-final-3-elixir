defmodule Dominio.Proyecto do
  @moduledoc """
  Representa el proyecto que desarrolla un equipo durante la Hackathon.
  Incluye la idea, descripción, avances y retroalimentación.
  """

  defstruct [
    :id,
    :nombre_equipo,
    :titulo,
    :descripcion,
    :categoria,     # Educación, Ambiental, Social
    :estado,        # :registrado, :en_progreso, :completado
    :avances,       # Lista de avances realizados
    :retroalimentacion, # Comentarios de mentores
    :fecha_registro,
    :fecha_actualizacion
  ]

  @doc """
  Crea un nuevo proyecto
  """
  def nuevo(nombre_equipo, titulo, descripcion, categoria) do
    %__MODULE__{
      id: generar_id(),
      nombre_equipo: nombre_equipo,
      titulo: titulo,
      descripcion: descripcion,
      categoria: categoria,
      estado: :registrado,
      avances: [],
      retroalimentacion: [],
      fecha_registro: DateTime.utc_now(),
      fecha_actualizacion: DateTime.utc_now()
    }
  end

  @doc """
  Agrega un avance al proyecto
  """
  def agregar_avance(proyecto, texto_avance) do
    timestamp = DateTime.utc_now()
    nuevo_avance = %{
      texto: texto_avance,
      fecha: timestamp
    }

    avances_actualizados = [nuevo_avance | proyecto.avances]

    %{proyecto |
      avances: avances_actualizados,
      estado: :en_progreso,
      fecha_actualizacion: timestamp
    }
  end

  @doc """
  Agrega retroalimentación de un mentor
  """
  def agregar_retroalimentacion(proyecto, nombre_mentor, comentario) do
    timestamp = DateTime.utc_now()
    nueva_retroalimentacion = %{
      mentor: nombre_mentor,
      comentario: comentario,
      fecha: timestamp
    }

    retroalimentacion_actualizada = [nueva_retroalimentacion | proyecto.retroalimentacion]

    %{proyecto |
      retroalimentacion: retroalimentacion_actualizada,
      fecha_actualizacion: timestamp
    }
  end

  @doc """
  Marca el proyecto como completado
  """
  def marcar_completado(proyecto) do
    %{proyecto |
      estado: :completado,
      fecha_actualizacion: DateTime.utc_now()
    }
  end

  @doc """
  Obtiene el último avance registrado
  """
  def ultimo_avance(proyecto) do
    case proyecto.avances do
      [] -> nil
      [ultimo | _] -> ultimo
    end
  end

  @doc """
  Cuenta cuántos avances tiene el proyecto
  """
  def contar_avances(proyecto) do
    length(proyecto.avances)
  end

  # Genera ID único
  defp generar_id() do
    :crypto.strong_rand_bytes(8)
    |> Base.encode16()
    |> String.downcase()
  end
end
