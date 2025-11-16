defmodule Dominio.Proyecto do
  @moduledoc """
  Representa el proyecto que desarrolla un equipo durante la Hackathon.
  Incluye la idea, descripción, avances y retroalimentación.
  Auto-creado al crear un equipo.
  """

  defstruct [
    :id,
    :nombre_equipo,
    :titulo,
    :descripcion,
    :categoria,     # Educación, Ambiental, Social
    :estado,        # :registrado, :en_progreso, :completado
    :estado_equipo, # :activo, :inactivo (sincronizado con el equipo)
    :avances,       # Lista de avances realizados
    :retroalimentacion, # Comentarios de mentores
    :suscriptores,  # PIDs que escuchan cambios en tiempo real
    :fecha_registro,
    :fecha_actualizacion
  ]

  @doc """
  Crea un nuevo proyecto automáticamente al crear un equipo
  """
  def nuevo(nombre_equipo, categoria, estado_equipo \\ :activo) do
    %__MODULE__{
      id: generar_id(),
      nombre_equipo: nombre_equipo,
      titulo: "Proyecto #{nombre_equipo}",
      descripcion: "Proyecto en desarrollo para la categoría #{categoria}",
      categoria: categoria,
      estado: :registrado,
      estado_equipo: estado_equipo,
      avances: [],
      retroalimentacion: [],
      suscriptores: [],
      fecha_registro: DateTime.utc_now(),
      fecha_actualizacion: DateTime.utc_now()
    }
  end

  @doc """
  Actualiza los detalles del proyecto (título y descripción)
  """
  def actualizar_detalles(proyecto, titulo, descripcion) do
    %{proyecto |
      titulo: titulo,
      descripcion: descripcion,
      fecha_actualizacion: DateTime.utc_now()
    }
  end

  @doc """
  Sincroniza el estado del equipo con el proyecto
  """
  def sincronizar_estado_equipo(proyecto, estado_equipo) do
    %{proyecto |
      estado_equipo: estado_equipo,
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
  Agrega un suscriptor para recibir notificaciones en tiempo real
  """
  def suscribir(proyecto, pid) do
    if pid in proyecto.suscriptores do
      proyecto
    else
      %{proyecto | suscriptores: [pid | proyecto.suscriptores]}
    end
  end

  @doc """
  Remueve un suscriptor
  """
  def desuscribir(proyecto, pid) do
    suscriptores_actualizados = List.delete(proyecto.suscriptores, pid)
    %{proyecto | suscriptores: suscriptores_actualizados}
  end

  @doc """
  Notifica a todos los suscriptores sobre un cambio
  """
  def notificar_suscriptores(proyecto, tipo_evento, datos) do
    Enum.each(proyecto.suscriptores, fn pid ->
      if Process.alive?(pid) do
        send(pid, {:actualizacion_proyecto, tipo_evento, proyecto.nombre_equipo, datos})
      end
    end)
    proyecto
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
