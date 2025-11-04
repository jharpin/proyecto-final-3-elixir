defmodule Adaptadores.Almacenamiento do
  @moduledoc """
  Módulo para almacenar datos en memoria usando Agent.
  Mantiene el estado de equipos, proyectos, participantes, mentores y mensajes.
  """

  use Agent

  @doc """
  Inicia el almacenamiento con datos vacíos
  """
  def iniciar() do
    estado_inicial = %{
      equipos: %{},
      proyectos: %{},
      participantes: %{},
      mentores: %{},
      mensajes: [],
      participante_actual: nil
    }

    Agent.start_link(fn -> estado_inicial end, name: __MODULE__)
  end

  # ========== OPERACIONES CON EQUIPOS ==========

  def guardar_equipo(equipo) do
    Agent.update(__MODULE__, fn estado ->
      equipos = Map.put(estado.equipos, equipo.nombre, equipo)
      %{estado | equipos: equipos}
    end)
  end

  def obtener_equipo(nombre_equipo) do
    Agent.get(__MODULE__, fn estado ->
      Map.get(estado.equipos, nombre_equipo)
    end)
  end

  def listar_equipos() do
    Agent.get(__MODULE__, fn estado ->
      Map.values(estado.equipos)
    end)
  end

  # ========== OPERACIONES CON PROYECTOS ==========

  def guardar_proyecto(proyecto) do
    Agent.update(__MODULE__, fn estado ->
      proyectos = Map.put(estado.proyectos, proyecto.nombre_equipo, proyecto)
      %{estado | proyectos: proyectos}
    end)
  end

  def obtener_proyecto(nombre_equipo) do
    Agent.get(__MODULE__, fn estado ->
      Map.get(estado.proyectos, nombre_equipo)
    end)
  end

  def listar_proyectos() do
    Agent.get(__MODULE__, fn estado ->
      Map.values(estado.proyectos)
    end)
  end

  # ========== OPERACIONES CON PARTICIPANTES ==========

  def guardar_participante(participante) do
    Agent.update(__MODULE__, fn estado ->
      participantes = Map.put(estado.participantes, participante.correo, participante)
      %{estado | participantes: participantes}
    end)
  end

  def obtener_participante(correo) do
    Agent.get(__MODULE__, fn estado ->
      Map.get(estado.participantes, correo)
    end)
  end

  def listar_participantes() do
    Agent.get(__MODULE__, fn estado ->
      Map.values(estado.participantes)
    end)
  end

  def establecer_participante_actual(participante) do
    Agent.update(__MODULE__, fn estado ->
      %{estado | participante_actual: participante}
    end)
  end

  def obtener_participante_actual() do
    Agent.get(__MODULE__, fn estado ->
      estado.participante_actual
    end)
  end

  # ========== OPERACIONES CON MENTORES ==========

  def guardar_mentor(mentor) do
    Agent.update(__MODULE__, fn estado ->
      mentores = Map.put(estado.mentores, mentor.nombre, mentor)
      %{estado | mentores: mentores}
    end)
  end

  def obtener_mentor(nombre) do
    Agent.get(__MODULE__, fn estado ->
      Map.get(estado.mentores, nombre)
    end)
  end

  def listar_mentores() do
    Agent.get(__MODULE__, fn estado ->
      Map.values(estado.mentores)
    end)
  end

  # ========== OPERACIONES CON MENSAJES ==========

  def guardar_mensaje(mensaje) do
    Agent.update(__MODULE__, fn estado ->
      mensajes = [mensaje | estado.mensajes]
      %{estado | mensajes: mensajes}
    end)
  end

  def obtener_mensajes(canal) do
    Agent.get(__MODULE__, fn estado ->
      estado.mensajes
      |> Enum.filter(fn msg -> msg.canal == canal end)
      |> Enum.reverse()
    end)
  end

  def obtener_mensajes_generales() do
    Agent.get(__MODULE__, fn estado ->
      estado.mensajes
      |> Enum.filter(fn msg -> msg.canal == "general" end)
      |> Enum.reverse()
    end)
  end
end
