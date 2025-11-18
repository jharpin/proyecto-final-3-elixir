defmodule Servicios.ServicioMentoria do
  @moduledoc """
  Servicio para gestionar mentores y su interacción con equipos.
  Los mentores pueden dar retroalimentación a los proyectos.
  """

  alias Dominio.Mentor
  alias Adaptadores.Almacenamiento

  @nombre_servicio :servicio_mentoria

  @doc """
  Inicia el servicio de mentoría
  """
  def iniciar() do
    pid = spawn(fn -> ciclo() end)
    Process.register(pid, @nombre_servicio)
    {:ok, pid}
  end

  # Ciclo principal
  defp ciclo() do
    receive do
      {remitente, :registrar, nombre, correo, especialidad} ->
        resultado = registrar_mentor(nombre, correo, especialidad)
        send(remitente, {:mentor_registrado, resultado})
        ciclo()

      {remitente, :listar} ->
        mentores = Almacenamiento.listar_mentores()
        send(remitente, {:lista_mentores, mentores})
        ciclo()

      {remitente, :obtener, nombre} ->
        mentor = Almacenamiento.obtener_mentor(nombre)
        send(remitente, {:info_mentor, mentor})
        ciclo()

      {remitente, :asignar_equipo, nombre_mentor, nombre_equipo} ->
        resultado = asignar_equipo_a_mentor(nombre_mentor, nombre_equipo)
        send(remitente, {:equipo_asignado, resultado})
        ciclo()

      {remitente, :dar_retroalimentacion, nombre_mentor, nombre_equipo, comentario} ->
        resultado = dar_retroalimentacion(nombre_mentor, nombre_equipo, comentario)
        send(remitente, {:retroalimentacion_dada, resultado})
        ciclo()

      :detener ->
        :ok
    end
  end

  # ========== FUNCIONES PRIVADAS ==========

  defp registrar_mentor(nombre, correo, especialidad) do
    case Almacenamiento.obtener_mentor(nombre) do
      nil ->
        case Mentor.nuevo(nombre, correo, especialidad) do
          {:ok, mentor} ->
            Almacenamiento.guardar_mentor(mentor)
            {:ok, mentor}

          {:error, mensaje} ->
            {:error, mensaje}
        end

      _mentor ->
        {:error, "Ya existe un mentor con ese nombre"}
    end
  end

  defp asignar_equipo_a_mentor(nombre_mentor, nombre_equipo) do
    case Almacenamiento.obtener_mentor(nombre_mentor) do
      nil ->
        {:error, "Mentor no encontrado"}

      mentor ->
        # Verificar que el equipo existe
        case Almacenamiento.obtener_equipo(nombre_equipo) do
          nil ->
            {:error, "El equipo no existe"}

          _equipo ->
            case Mentor.asignar_equipo(mentor, nombre_equipo) do
              {:ok, mentor_actualizado} ->
                Almacenamiento.guardar_mentor(mentor_actualizado)
                {:ok, "Equipo asignado al mentor"}

              {:error, msg} ->
                {:error, msg}
            end
        end
    end
  end

  defp dar_retroalimentacion(nombre_mentor, nombre_equipo, comentario) do
    case Almacenamiento.obtener_mentor(nombre_mentor) do
      nil ->
        {:error, "Mentor no encontrado"}

      mentor ->
        # Verificar que el equipo está asignado al mentor
        if Mentor.tiene_equipo?(mentor, nombre_equipo) do
          # Obtener el proyecto y agregar retroalimentación
          case Almacenamiento.obtener_proyecto(nombre_equipo) do
            nil ->
              {:error, "No existe un proyecto para ese equipo"}

            proyecto ->
              # Agregar retroalimentación al proyecto
              proyecto_actualizado = Dominio.Proyecto.agregar_retroalimentacion(
                proyecto,
                nombre_mentor,
                comentario
              )
              Almacenamiento.guardar_proyecto(proyecto_actualizado)
              {:ok, "Retroalimentación enviada al equipo"}
          end
        else
          {:error, "Este equipo no está asignado a tu mentoría"}
        end
    end
  end

  # ========== API PÚBLICA ==========

  @doc """
  Solicita registrar un mentor
  """
  def solicitar_registrar(nombre, correo, especialidad) do
    send(@nombre_servicio, {self(), :registrar, nombre, correo, especialidad})

    receive do
      {:mentor_registrado, resultado} -> resultado
    after
      5000 -> {:error, "Timeout"}
    end
  end

  @doc """
  Solicita listar mentores
  """
  def solicitar_listar() do
    send(@nombre_servicio, {self(), :listar})

    receive do
      {:lista_mentores, mentores} -> mentores
    after
      5000 -> []
    end
  end

  @doc """
  Solicita asignar un equipo a un mentor
  """
  def solicitar_asignar_equipo(nombre_mentor, nombre_equipo) do
    send(@nombre_servicio, {self(), :asignar_equipo, nombre_mentor, nombre_equipo})

    receive do
      {:equipo_asignado, resultado} -> resultado
    after
      5000 -> {:error, "Timeout"}
    end
  end
end
