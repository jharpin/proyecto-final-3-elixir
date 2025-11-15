defmodule Servicios.ServicioEquipos do
  @moduledoc """
  Servicio para gestionar equipos.
  Implementa concurrencia usando spawn, send y receive.
  """

  alias Dominio.Equipo
  alias Adaptadores.Almacenamiento

  @nombre_servicio :servicio_equipos

  @doc """
  Inicia el servicio de equipos
  """
  def iniciar() do
    pid = spawn(fn -> ciclo() end)
    Process.register(pid, @nombre_servicio)
    {:ok, pid}
  end

  @doc """
  Ciclo principal del servicio
  """
  defp ciclo() do
    receive do
      {remitente, :crear, nombre, tema, lider} ->
        resultado = crear_equipo(nombre, tema, lider)
        send(remitente, {:equipo_creado, resultado})
        ciclo()

      {remitente, :listar} ->
        equipos = Almacenamiento.listar_equipos()
        send(remitente, {:lista_equipos, equipos})
        ciclo()

      {remitente, :obtener, nombre_equipo} ->
        equipo = Almacenamiento.obtener_equipo(nombre_equipo)
        send(remitente, {:info_equipo, equipo})
        ciclo()

      {remitente, :agregar_miembro, nombre_equipo, nombre_miembro} ->
        resultado = agregar_miembro_a_equipo(nombre_equipo, nombre_miembro)
        send(remitente, {:miembro_agregado, resultado})
        ciclo()

      {remitente, :remover_miembro, nombre_equipo, nombre_miembro} ->
        resultado = remover_miembro_de_equipo(nombre_equipo, nombre_miembro)
        send(remitente, {:miembro_removido, resultado})
        ciclo()

      :detener ->
        :ok
    end
  end

  # ========== FUNCIONES PRIVADAS ==========

  defp crear_equipo(nombre, tema, lider) do
    # Verificar si ya existe un equipo con ese nombre
    case Almacenamiento.obtener_equipo(nombre) do
      nil ->
        # Buscar al participante líder por nombre
        participante = Almacenamiento.listar_participantes()
                      |> Enum.find(fn p -> p.nombre == lider end)

        # Crear el equipo
        equipo = Equipo.nuevo(nombre, tema, lider)
        Almacenamiento.guardar_equipo(equipo)

        # Si el líder existe como participante, asignarle el equipo
        if participante do
          participante_actualizado = Dominio.Participante.asignar_equipo(participante, nombre)
          Almacenamiento.guardar_participante(participante_actualizado)
        end

        {:ok, equipo}

      _equipo ->
        {:error, "Ya existe un equipo con ese nombre"}
    end
  end

  defp agregar_miembro_a_equipo(nombre_equipo, nombre_miembro) do
    case Almacenamiento.obtener_equipo(nombre_equipo) do
      nil ->
        {:error, "El equipo no existe"}

      equipo ->
        # Buscar al participante por nombre para verificar si ya tiene equipo
        participante = Almacenamiento.listar_participantes()
                      |> Enum.find(fn p -> p.nombre == nombre_miembro end)

        cond do
          participante == nil ->
            {:error, "El participante no existe. Debe registrarse primero."}

          participante.equipo != nil and participante.equipo != nombre_equipo ->
            {:error, "Ya perteneces al equipo '#{participante.equipo}'. Usa /salir-equipo primero."}

          nombre_miembro in equipo.miembros ->
            {:error, "Este participante ya está en el equipo"}

          true ->
            case Equipo.agregar_miembro(equipo, nombre_miembro) do
              {:ok, equipo_actualizado} ->
                Almacenamiento.guardar_equipo(equipo_actualizado)
                # Actualizar el participante con el equipo asignado
                if participante do
                  participante_actualizado = Dominio.Participante.asignar_equipo(participante, nombre_equipo)
                  Almacenamiento.guardar_participante(participante_actualizado)
                end
                {:ok, "#{nombre_miembro} se unió al equipo"}

              {:error, msg} ->
                {:error, msg}
            end
        end
    end
  end

  defp remover_miembro_de_equipo(nombre_equipo, nombre_miembro) do
    case Almacenamiento.obtener_equipo(nombre_equipo) do
      nil ->
        {:error, "El equipo no existe"}

      equipo ->
        case Equipo.remover_miembro(equipo, nombre_miembro) do
          {:ok, equipo_actualizado} ->
            Almacenamiento.guardar_equipo(equipo_actualizado)

            # Desasignar el equipo del participante
            participante = Almacenamiento.listar_participantes()
                          |> Enum.find(fn p -> p.nombre == nombre_miembro end)

            if participante do
              participante_actualizado = Dominio.Participante.desasignar_equipo(participante)
              Almacenamiento.guardar_participante(participante_actualizado)
            end

            {:ok, "#{nombre_miembro} fue removido del equipo"}

          {:error, msg} ->
            {:error, msg}
        end
    end
  end

  # ========== API PÚBLICA ==========

  @doc """
  Solicita crear un equipo nuevo
  """
  def solicitar_crear(nombre, tema, lider) do
    send(@nombre_servicio, {self(), :crear, nombre, tema, lider})

    receive do
      {:equipo_creado, resultado} -> resultado
    after
      5000 -> {:error, "Timeout"}
    end
  end

  @doc """
  Solicita listar todos los equipos
  """
  def solicitar_listar() do
    send(@nombre_servicio, {self(), :listar})

    receive do
      {:lista_equipos, equipos} -> equipos
    after
      5000 -> []
    end
  end

  @doc """
  Solicita obtener información de un equipo
  """
  def solicitar_obtener(nombre_equipo) do
    send(@nombre_servicio, {self(), :obtener, nombre_equipo})

    receive do
      {:info_equipo, equipo} -> equipo
    after
      5000 -> nil
    end
  end

  @doc """
  Solicita agregar un miembro a un equipo
  """
  def solicitar_agregar_miembro(nombre_equipo, nombre_miembro) do
    send(@nombre_servicio, {self(), :agregar_miembro, nombre_equipo, nombre_miembro})

    receive do
      {:miembro_agregado, resultado} -> resultado
    after
      5000 -> {:error, "Timeout"}
    end
  end
end
