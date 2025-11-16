defmodule Servicios.ServicioProyectos do
  @moduledoc """
  Servicio para gestionar proyectos de los equipos.
  Maneja registro de ideas, avances y retroalimentación.
  Los proyectos se crean automáticamente al crear un equipo.
  Soporta actualizaciones en tiempo real mediante suscripciones.
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
      # Crear proyecto automáticamente
      {remitente, :crear_automatico, nombre_equipo, categoria, estado_equipo} ->
        resultado = crear_proyecto_automatico(nombre_equipo, categoria, estado_equipo)
        send(remitente, {:proyecto_creado, resultado})
        ciclo()

      # Actualizar detalles del proyecto
      {remitente, :actualizar_detalles, nombre_equipo, titulo, descripcion} ->
        resultado = actualizar_detalles_proyecto(nombre_equipo, titulo, descripcion)
        send(remitente, {:proyecto_actualizado, resultado})
        ciclo()

      {remitente, :obtener, nombre_equipo} ->
        proyecto = Almacenamiento.obtener_proyecto(nombre_equipo)
        send(remitente, {:info_proyecto, proyecto})
        ciclo()

      {remitente, :listar} ->
        proyectos = Almacenamiento.listar_proyectos()
        send(remitente, {:lista_proyectos, proyectos})
        ciclo()

      {remitente, :listar_por_estado_equipo, estado_equipo} ->
        proyectos = listar_proyectos_por_estado_equipo(estado_equipo)
        send(remitente, {:lista_proyectos, proyectos})
        ciclo()

      {remitente, :listar_por_categoria, categoria} ->
        proyectos = listar_proyectos_por_categoria(categoria)
        send(remitente, {:lista_proyectos, proyectos})
        ciclo()

      # Agregar avance con notificación en tiempo real
      {remitente, :agregar_avance, nombre_equipo, texto_avance} ->
        resultado = agregar_avance_tiempo_real(nombre_equipo, texto_avance)
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

      # Suscripción para tiempo real
      {remitente, :suscribir, nombre_equipo, pid_suscriptor} ->
        resultado = suscribir_a_proyecto(nombre_equipo, pid_suscriptor)
        send(remitente, {:suscripcion, resultado})
        ciclo()

      # Sincronizar estado del equipo
      {remitente, :sincronizar_estado_equipo, nombre_equipo, estado_equipo} ->
        resultado = sincronizar_estado(nombre_equipo, estado_equipo)
        send(remitente, {:estado_sincronizado, resultado})
        ciclo()

      :detener ->
        :ok
    end
  end

  # ========== FUNCIONES PRIVADAS ==========

  defp crear_proyecto_automatico(nombre_equipo, categoria, estado_equipo) do
    # Verificar que el equipo existe
    case Almacenamiento.obtener_equipo(nombre_equipo) do
      nil ->
        {:error, "El equipo no existe"}

      _equipo ->
        # Verificar si ya tiene proyecto
        case Almacenamiento.obtener_proyecto(nombre_equipo) do
          nil ->
            proyecto = Proyecto.nuevo(nombre_equipo, categoria, estado_equipo)
            Almacenamiento.guardar_proyecto(proyecto)
            {:ok, proyecto}

          _proyecto ->
            {:error, "Este equipo ya tiene un proyecto registrado"}
        end
    end
  end

  defp actualizar_detalles_proyecto(nombre_equipo, titulo, descripcion) do
    case Almacenamiento.obtener_proyecto(nombre_equipo) do
      nil ->
        {:error, "No existe un proyecto para este equipo"}

      proyecto ->
        proyecto_actualizado = Proyecto.actualizar_detalles(proyecto, titulo, descripcion)
        Almacenamiento.guardar_proyecto(proyecto_actualizado)
        {:ok, "Detalles del proyecto actualizados"}
    end
  end

  defp sincronizar_estado(nombre_equipo, estado_equipo) do
    case Almacenamiento.obtener_proyecto(nombre_equipo) do
      nil ->
        {:error, "No existe un proyecto para este equipo"}

      proyecto ->
        proyecto_actualizado = Proyecto.sincronizar_estado_equipo(proyecto, estado_equipo)
        Almacenamiento.guardar_proyecto(proyecto_actualizado)
        {:ok, "Estado sincronizado"}
    end
  end

  defp agregar_avance_tiempo_real(nombre_equipo, texto_avance) do
    case Almacenamiento.obtener_proyecto(nombre_equipo) do
      nil ->
        {:error, "No existe un proyecto para este equipo"}

      proyecto ->
        # Agregar el avance
        proyecto_actualizado = Proyecto.agregar_avance(proyecto, texto_avance)

        # Notificar a suscriptores en tiempo real
        datos_notificacion = %{
          texto: texto_avance,
          fecha: DateTime.utc_now(),
          total_avances: length(proyecto_actualizado.avances)
        }

        Proyecto.notificar_suscriptores(proyecto_actualizado, :nuevo_avance, datos_notificacion)

        # Guardar el proyecto actualizado
        Almacenamiento.guardar_proyecto(proyecto_actualizado)

        # Notificar al chat general
        timestamp = DateTime.utc_now() |> Calendar.strftime("%H:%M")
        mensaje_notificacion = "[#{timestamp}] 🚀 El equipo #{nombre_equipo} ha registrado un nuevo avance"

        mensaje = %{
          canal: "general",
          autor: "Sistema",
          texto: mensaje_notificacion,
          timestamp: DateTime.utc_now()
        }
        Almacenamiento.guardar_mensaje(mensaje)

        {:ok, "Avance registrado y notificado en tiempo real"}
    end
  end

  defp suscribir_a_proyecto(nombre_equipo, pid_suscriptor) do
    case Almacenamiento.obtener_proyecto(nombre_equipo) do
      nil ->
        {:error, "No existe un proyecto para este equipo"}

      proyecto ->
        proyecto_actualizado = Proyecto.suscribir(proyecto, pid_suscriptor)
        Almacenamiento.guardar_proyecto(proyecto_actualizado)
        {:ok, "Suscrito a actualizaciones del proyecto"}
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
    proyectos = Almacenamiento.listar_proyectos()
    # Filtrar directamente por el estado_equipo almacenado en el proyecto
    Enum.filter(proyectos, fn proy -> proy.estado_equipo == estado_equipo end)
  end

  defp listar_proyectos_por_categoria(categoria) do
    proyectos = Almacenamiento.listar_proyectos()
    Enum.filter(proyectos, fn proy -> proy.categoria == categoria end)
  end

  # ========== API PÚBLICA ==========

  @doc """
  Solicita crear un proyecto automáticamente
  """
  def solicitar_crear_automatico(nombre_equipo, categoria, estado_equipo \\ :activo) do
    send(@nombre_servicio, {self(), :crear_automatico, nombre_equipo, categoria, estado_equipo})

    receive do
      {:proyecto_creado, resultado} -> resultado
    after
      5000 -> {:error, "Timeout"}
    end
  end

  @doc """
  Solicita actualizar detalles del proyecto
  """
  def solicitar_actualizar_detalles(nombre_equipo, titulo, descripcion) do
    send(@nombre_servicio, {self(), :actualizar_detalles, nombre_equipo, titulo, descripcion})

    receive do
      {:proyecto_actualizado, resultado} -> resultado
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
  Solicita agregar un avance con notificación en tiempo real
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
  Solicita suscribirse a actualizaciones del proyecto
  """
  def solicitar_suscribir(nombre_equipo, pid_suscriptor \\ self()) do
    send(@nombre_servicio, {self(), :suscribir, nombre_equipo, pid_suscriptor})

    receive do
      {:suscripcion, resultado} -> resultado
    after
      5000 -> {:error, "Timeout"}
    end
  end

  @doc """
  Solicita sincronizar el estado del equipo
  """
  def solicitar_sincronizar_estado(nombre_equipo, estado_equipo) do
    send(@nombre_servicio, {self(), :sincronizar_estado_equipo, nombre_equipo, estado_equipo})

    receive do
      {:estado_sincronizado, resultado} -> resultado
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
    send(@nombre_servicio, {self(), :listar_por_estado_equipo, estado_equipo})

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
