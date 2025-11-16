defmodule Servicios.ServicioProyectos do
  @moduledoc """
  Servicio para gestionar proyectos de los equipos.
  Maneja registro de ideas, avances y retroalimentación.
  """

  alias Dominio.Proyecto
  alias Adaptadores.Almacenamiento

  @nombre_servicio :servicio_proyectos

  @doc """
  Inicia el servicio
  """
  def iniciar() do
    pid = spawn(fn -> ciclo() end)
    Process.register(pid, @nombre_servicio)
    {:ok, pid}
  end

  @doc """
  Ciclo principal que recibe mensajes
  """
  defp ciclo() do
    receive do
      {remitente, :crear, nombre_equipo, titulo, descripcion, categoria} ->
        resultado = crear_proyecto(nombre_equipo, titulo, descripcion, categoria)
        send(remitente, {:proyecto_creado, resultado})
        ciclo()

      {remitente, :obtener, nombre_equipo} ->
        proyecto = Almacenamiento.obtener_proyecto(nombre_equipo)
        send(remitente, {:info_proyecto, proyecto})
        ciclo()

      {remitente, :listar} ->
        proyectos = Almacenamiento.listar_proyectos()
        send(remitente, {:lista_proyectos, proyectos})
        ciclo()

      {remitente, :listar_por_estado, estado_equipo} ->
        proyectos = listar_proyectos_por_estado_equipo(estado_equipo)
        send(remitente, {:lista_proyectos, proyectos})
        ciclo()

      {remitente, :listar_por_categoria, categoria} ->
        proyectos = listar_proyectos_por_categoria(categoria)
        send(remitente, {:lista_proyectos, proyectos})
        ciclo()

      {remitente, :agregar_avance, nombre_equipo, texto_avance} ->
        resultado = agregar_avance(nombre_equipo, texto_avance)
        send(remitente, {:avance_agregado, resultado})
        ciclo()

      {remitente, :agregar_retroalimentacion, nombre_equipo, nombre_mentor, comentario} ->
        resultado = agregar_retroalimentacion(nombre_equipo, nombre_mentor, comentario)
        send(remitente, {:retroalimentacion_agregada, resultado})
        ciclo()

      {remitente, :completar, nombre_equipo} ->
        resultado = completar_proyecto(nombre_equipo)
        send(remitente, {:proyecto_completado, resultado})
        ciclo()

      :detener ->
        :ok
    end
  end

  # ========== FUNCIONES PRIVADAS ==========

  defp crear_proyecto(nombre_equipo, titulo, descripcion, categoria) do
    # Verificar que el equipo existe
    case Almacenamiento.obtener_equipo(nombre_equipo) do
      nil ->
        {:error, "El equipo no existe"}

      _equipo ->
        # Verificar si ya tiene proyecto
        case Almacenamiento.obtener_proyecto(nombre_equipo) do
          nil ->
            proyecto = Proyecto.nuevo(nombre_equipo, titulo, descripcion, categoria)
            Almacenamiento.guardar_proyecto(proyecto)
            {:ok, proyecto}

          _proyecto ->
            {:error, "Este equipo ya tiene un proyecto registrado"}
        end
    end
  end

  defp agregar_avance(nombre_equipo, texto_avance) do
    case Almacenamiento.obtener_proyecto(nombre_equipo) do
      nil ->
        {:error, "No existe un proyecto para este equipo"}

      proyecto ->
        proyecto_actualizado = Proyecto.agregar_avance(proyecto, texto_avance)
        Almacenamiento.guardar_proyecto(proyecto_actualizado)

        # Notificar al chat general sobre el avance
        timestamp = DateTime.utc_now() |> Calendar.strftime("%H:%M")
        mensaje_notificacion = "[#{timestamp}] El equipo #{nombre_equipo} ha registrado un nuevo avance"

        mensaje = %{
          canal: "general",
          autor: "Sistema",
          texto: mensaje_notificacion,
          timestamp: DateTime.utc_now()
        }
        Almacenamiento.guardar_mensaje(mensaje)

        {:ok, "Avance registrado correctamente"}
    end
  end

  defp agregar_retroalimentacion(nombre_equipo, nombre_mentor, comentario) do
    case Almacenamiento.obtener_proyecto(nombre_equipo) do
      nil ->
        {:error, "No existe un proyecto para este equipo"}

      proyecto ->
        proyecto_actualizado = Proyecto.agregar_retroalimentacion(proyecto, nombre_mentor, comentario)
        Almacenamiento.guardar_proyecto(proyecto_actualizado)
        {:ok, "Retroalimentación agregada"}
    end
  end

  defp completar_proyecto(nombre_equipo) do
    case Almacenamiento.obtener_proyecto(nombre_equipo) do
      nil ->
        {:error, "No existe un proyecto para este equipo"}

      proyecto ->
        proyecto_completado = Proyecto.marcar_completado(proyecto)
        Almacenamiento.guardar_proyecto(proyecto_completado)
        {:ok, "Proyecto marcado como completado"}
    end
  end

  defp listar_proyectos_por_estado_equipo(estado_equipo) do
    equipos = Almacenamiento.listar_equipos()
    proyectos = Almacenamiento.listar_proyectos()

    equipos_filtrados = Enum.filter(equipos, fn eq -> eq.estado == estado_equipo end)
    nombres_equipos = Enum.map(equipos_filtrados, fn eq -> eq.nombre end)

    Enum.filter(proyectos, fn proy -> proy.nombre_equipo in nombres_equipos end)
  end

  defp listar_proyectos_por_categoria(categoria) do
    proyectos = Almacenamiento.listar_proyectos()
    Enum.filter(proyectos, fn proy -> proy.categoria == categoria end)
  end

  # ========== API PÚBLICA ==========

  @doc """
  Solicita crear un proyecto
  """
  def solicitar_crear(nombre_equipo, titulo, descripcion, categoria) do
    send(@nombre_servicio, {self(), :crear, nombre_equipo, titulo, descripcion, categoria})

    receive do
      {:proyecto_creado, resultado} -> resultado
    after
      5000 -> {:error, "Timeout"}
    end
  end

  @doc """
  Solicita obtener un proyecto
  """
  def solicitar_obtener(nombre_equipo) do
    send(@nombre_servicio, {self(), :obtener, nombre_equipo})

    receive do
      {:info_proyecto, proyecto} -> proyecto
    after
      5000 -> nil
    end
  end

  @doc """
  Solicita agregar un avance
  """
  def solicitar_agregar_avance(nombre_equipo, texto_avance) do
    send(@nombre_servicio, {self(), :agregar_avance, nombre_equipo, texto_avance})

    receive do
      {:avance_agregado, resultado} -> resultado
    after
      5000 -> {:error, "Timeout"}
    end
  end

  @doc """
  Solicita listar todos los proyectos
  """
  def solicitar_listar() do
    send(@nombre_servicio, {self(), :listar})

    receive do
      {:lista_proyectos, proyectos} -> proyectos
    after
      5000 -> []
    end
  end

  @doc """
  Solicita listar proyectos filtrados por estado del equipo
  """
  def solicitar_listar_por_estado(estado_equipo) do
    send(@nombre_servicio, {self(), :listar_por_estado, estado_equipo})

    receive do
      {:lista_proyectos, proyectos} -> proyectos
    after
      5000 -> []
    end
  end

  @doc """
  Solicita listar proyectos filtrados por categoria
  """
  def solicitar_listar_por_categoria(categoria) do
    send(@nombre_servicio, {self(), :listar_por_categoria, categoria})

    receive do
      {:lista_proyectos, proyectos} -> proyectos
    after
      5000 -> []
    end
  end
end
