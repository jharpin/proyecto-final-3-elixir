defmodule Adaptadores.ProcesadorComandos do
  @moduledoc """
  Procesa los comandos que ingresa el usuario.
  Usa pattern matching para identificar el comando y sus argumentos.
  """

  @doc """
  Parsea un comando ingresado por el usuario
  Retorna {:comando, argumentos}
  """
  def parsear(entrada) do
    entrada
    |> String.trim()
    |> String.split(" ", parts: 2)
    |> procesar_comando()
  end

  # /registrar - Registrar nuevo participante
  defp procesar_comando(["/registrar"]) do
    {:registrar, nil}
  end

  # /equipos - Listar todos los equipos
  defp procesar_comando(["/equipos"]) do
    {:listar_equipos, nil}
  end

  # /crear equipo <nombre> <tema>
  defp procesar_comando(["/crear", resto]) do
    case String.split(resto, " ", parts: 2) do
      ["equipo", info_equipo] ->
        case String.split(info_equipo, " ", parts: 2) do
          [nombre, tema] -> {:crear_equipo, %{nombre: nombre, tema: tema}}
          _ -> {:error, "Uso: /crear equipo <nombre> <tema>"}
        end

      ["proyecto", info_proyecto] ->
        {:crear_proyecto, info_proyecto}

      _ -> {:error, "Comando /crear no reconocido"}
    end
  end

  # /unirse <nombre_equipo>
  defp procesar_comando(["/unirse", nombre_equipo]) do
    {:unirse_equipo, nombre_equipo}
  end

  # /proyecto <nombre_equipo>
  defp procesar_comando(["/proyecto", nombre_equipo]) do
    {:ver_proyecto, nombre_equipo}
  end

  # /avance <nombre_equipo>
  defp procesar_comando(["/avance", nombre_equipo]) do
    {:agregar_avance, nombre_equipo}
  end

  # /chat <nombre_equipo>
  defp procesar_comando(["/chat", nombre_equipo]) do
    {:abrir_chat, nombre_equipo}
  end

  # /mentores - Listar mentores
  defp procesar_comando(["/mentores"]) do
    {:listar_mentores, nil}
  end

  # /participantes - Listar participantes
  defp procesar_comando(["/participantes"]) do
    {:listar_participantes, nil}
  end

  # /usuarios - Alias para listar participantes (con equipos)
  defp procesar_comando(["/usuarios"]) do
    {:listar_participantes, nil}
  end

  # /salir-equipo - Salir del equipo actual
  defp procesar_comando(["/salir-equipo"]) do
    {:salir_equipo, nil}
  end

  # /ayuda - Mostrar ayuda
  defp procesar_comando(["/ayuda"]) do
    {:ayuda, nil}
  end

  # /salir - Salir del sistema
  defp procesar_comando(["/salir"]) do
    {:salir, nil}
  end

  # Comando desconocido
  defp procesar_comando(_) do
    {:desconocido, nil}
  end

  @doc """
  Muestra el menú de ayuda con todos los comandos
  """
  def mostrar_ayuda() do
    """

 COMANDOS DISPONIBLES
        CODE4FUTURE


GESTION DE PARTICIPANTES:
  /registrar
        Registrarse en el sistema

  /participantes o /usuarios
        Ver todos los participantes con sus equipos

  /salir-equipo
        Salir del equipo actual


GESTION DE EQUIPOS:
  /equipos
        Ver todos los equipos

  /crear equipo <nombre> <tema>
        Crear un equipo nuevo

  /unirse <equipo>
        Unirse a un equipo


GESTION DE PROYECTOS:
  /proyecto <equipo>
        Ver proyecto de un equipo

  /avance <equipo>
        Agregar avance al proyecto

  /crear proyecto
        Registrar proyecto del equipo


COMUNICACION:
  /chat <equipo>
        Abrir chat del equipo

  /chat general
        Chat general de la hackathon


MENTORIA:
  /mentores
        Ver mentores disponibles


SISTEMA:
  /ayuda
        Mostrar esta ayuda

  /salir
        Salir del sistema

"""
  end
end
