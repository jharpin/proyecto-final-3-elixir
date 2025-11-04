defmodule Servicios.ServicioParticipantes do
  @moduledoc """
  Servicio para gestionar participantes.
  Usa procesos con spawn/send/receive como en los ejemplos del profesor.
  """

  alias Dominio.Participante
  alias Adaptadores.Almacenamiento

  @nombre_servicio :servicio_participantes

  @doc """
  Inicia el servicio de participantes
  """
  def iniciar() do
    pid = spawn(fn -> ciclo() end)
    Process.register(pid, @nombre_servicio)
    {:ok, pid}
  end

  @doc """
  Ciclo principal que recibe y procesa mensajes
  """
  defp ciclo() do
    receive do
      {remitente, :registrar, nombre, correo, rol} ->
        resultado = registrar_participante(nombre, correo, rol)
        send(remitente, {:participante_registrado, resultado})
        ciclo()

      {remitente, :obtener, correo} ->
        participante = Almacenamiento.obtener_participante(correo)
        send(remitente, {:info_participante, participante})
        ciclo()

      {remitente, :listar} ->
        participantes = Almacenamiento.listar_participantes()
        send(remitente, {:lista_participantes, participantes})
        ciclo()

      {remitente, :asignar_equipo, correo, nombre_equipo} ->
        resultado = asignar_equipo_a_participante(correo, nombre_equipo)
        send(remitente, {:equipo_asignado, resultado})
        ciclo()

      {remitente, :agregar_habilidad, correo, habilidad} ->
        resultado = agregar_habilidad_a_participante(correo, habilidad)
        send(remitente, {:habilidad_agregada, resultado})
        ciclo()

      :detener ->
        :ok
    end
  end

  # ========== FUNCIONES PRIVADAS ==========

  defp registrar_participante(nombre, correo, rol) do
    # Verificar si ya existe
    case Almacenamiento.obtener_participante(correo) do
      nil ->
        participante = Participante.nuevo(nombre, correo, rol)
        Almacenamiento.guardar_participante(participante)
        {:ok, participante}

      _participante ->
        {:error, "Ya existe un participante con ese correo"}
    end
  end

  defp asignar_equipo_a_participante(correo, nombre_equipo) do
    case Almacenamiento.obtener_participante(correo) do
      nil ->
        {:error, "Participante no encontrado"}

      participante ->
        # Verificar que el equipo existe
        case Almacenamiento.obtener_equipo(nombre_equipo) do
          nil ->
            {:error, "El equipo no existe"}

          _equipo ->
            participante_actualizado = Participante.asignar_equipo(participante, nombre_equipo)
            Almacenamiento.guardar_participante(participante_actualizado)
            {:ok, "Te uniste al equipo #{nombre_equipo}"}
        end
    end
  end

  defp agregar_habilidad_a_participante(correo, habilidad) do
    case Almacenamiento.obtener_participante(correo) do
      nil ->
        {:error, "Participante no encontrado"}

      participante ->
        case Participante.agregar_habilidad(participante, habilidad) do
          {:ok, participante_actualizado} ->
            Almacenamiento.guardar_participante(participante_actualizado)
            {:ok, "Habilidad agregada correctamente"}

          {:error, msg} ->
            {:error, msg}
        end
    end
  end

  # ========== API PÚBLICA (Para usar desde otros módulos) ==========

  @doc """
  Solicita registrar un participante
  """
  def solicitar_registrar(nombre, correo, rol \\ :participante) do
    send(@nombre_servicio, {self(), :registrar, nombre, correo, rol})

    receive do
      {:participante_registrado, resultado} -> resultado
    after
      5000 -> {:error, "Timeout al registrar"}
    end
  end

  @doc """
  Solicita obtener un participante
  """
  def solicitar_obtener(correo) do
    send(@nombre_servicio, {self(), :obtener, correo})

    receive do
      {:info_participante, participante} -> participante
    after
      5000 -> nil
    end
  end

  @doc """
  Solicita listar todos los participantes
  """
  def solicitar_listar() do
    send(@nombre_servicio, {self(), :listar})

    receive do
      {:lista_participantes, participantes} -> participantes
    after
      5000 -> []
    end
  end

  @doc """
  Solicita asignar un equipo a un participante
  """
  def solicitar_asignar_equipo(correo, nombre_equipo) do
    send(@nombre_servicio, {self(), :asignar_equipo, correo, nombre_equipo})

    receive do
      {:equipo_asignado, resultado} -> resultado
    after
      5000 -> {:error, "Timeout"}
    end
  end
end
