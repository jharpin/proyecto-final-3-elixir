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

  # /registrar-mentor - Registrar nuevo mentor
  defp procesar_comando(["/registrar-mentor"]) do
    {:registrar_mentor, nil}
  end

  # /equipos - Listar todos los equipos
  defp procesar_comando(["/equipos"]) do
    {:listar_equipos, nil}
  end

  # /crear equipo <nombre> <tema>
  # /crear proyecto <nombre_equipo>
  defp procesar_comando(["/crear", resto]) do
    case String.split(resto, " ", parts: 2) do
      ["equipo", info_equipo] ->
        case String.split(info_equipo, " ", parts: 2) do
          [nombre, tema] -> {:crear_equipo, %{nombre: nombre, tema: tema}}
          _ -> {:error, "Uso: /crear equipo <nombre> <tema>"}
        end

      ["proyecto", nombre_equipo] ->
        {:crear_proyecto, %{nombre_equipo: nombre_equipo}}

      _ -> {:error, "Comando /crear no reconocido. Usa: /crear equipo o /crear proyecto"}
    end
  end

  # /listar proyectos - Listar todos los proyectos
  defp procesar_comando(["/listar", "proyectos"]) do
    {:listar_proyectos, nil}
  end

  # /listar proyectos activos - Proyectos de equipos activos
  defp procesar_comando(["/listar", resto]) do
    case String.split(resto, " ", parts: 2) do
      ["proyectos", "activos"] ->
        {:listar_proyectos_activos, nil}

      ["proyectos", "inactivos"] ->
        {:listar_proyectos_inactivos, nil}

      ["proyectos", categoria] ->
        {:listar_proyectos_categoria, categoria}

      _ ->
        {:error, "Comando /listar no reconocido"}
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

  # /activar <nombre_equipo> - Activar equipo
  defp procesar_comando(["/activar", nombre_equipo]) do
    {:activar_equipo, nombre_equipo}
  end

  # /desactivar <nombre_equipo> - Desactivar equipo
  defp procesar_comando(["/desactivar", nombre_equipo]) do
    {:desactivar_equipo, nombre_equipo}
  end

  # /actualizar proyecto <nombre_equipo> - Actualizar detalles del proyecto
  defp procesar_comando(["/actualizar", resto]) do
    case String.split(resto, " ", parts: 2) do
      ["proyecto", nombre_equipo] ->
        {:actualizar_proyecto, nombre_equipo}

      _ ->
        {:error, "Uso: /actualizar proyecto <nombre_equipo>"}
    end
  end

  # /monitorear <nombre_equipo> - Monitorear proyecto en tiempo real
  defp procesar_comando(["/monitorear", nombre_equipo]) do
    {:monitorear_proyecto, nombre_equipo}
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

╔══════════════════════════════════════════════════════════════════╗
║          COMANDOS DISPONIBLES - CODE4FUTURE HACKATHON           ║
╚══════════════════════════════════════════════════════════════════╝

📋 GESTIÓN DE PARTICIPANTES:
  /registrar
        Registrarse como participante en el sistema

  /registrar-mentor
        Registrarse como mentor

  /participantes
        Ver todos los participantes registrados


👥 GESTIÓN DE EQUIPOS:
  /equipos
        Ver todos los equipos

  /crear equipo <nombre> <tema>
        Crear un equipo nuevo
        Ejemplo: /crear equipo Innovadores Educacion

  /unirse <equipo>
        Unirse a un equipo existente

  /activar <equipo>
        Activar un equipo

  /desactivar <equipo>
        Desactivar un equipo


📝 GESTIÓN DE PROYECTOS:
  /crear proyecto <nombre_equipo>
        Crear proyecto para un equipo
        Ejemplo: /crear proyecto Innovadores

  /proyecto <equipo>
        Ver detalles del proyecto de un equipo

  /actualizar proyecto <equipo>
        Actualizar título y descripción del proyecto

  /avance <equipo>
        Agregar avance al proyecto (notifica en tiempo real)

  /monitorear <equipo>
        Monitorear proyecto en tiempo real

  /listar proyectos
        Ver todos los proyectos

  /listar proyectos activos
        Ver proyectos de equipos activos

  /listar proyectos inactivos
        Ver proyectos de equipos inactivos

  /listar proyectos <categoria>
        Ver proyectos por categoría
        Categorías: Educacion, Ambiental, Social


💬 COMUNICACIÓN:
  /chat <equipo>
        Abrir chat del equipo

  /chat general
        Chat general de la hackathon


👨‍🏫 MENTORÍA:
  /mentores
        Ver mentores disponibles


⚙️  SISTEMA:
  /ayuda
        Mostrar esta ayuda

  /salir
        Salir del sistema

"""
  end
end
